import { strict as assert } from "node:assert";
import { Webhook } from "npm:standardwebhooks@1.0.0";
import { createMailtrapHook } from "./handler.ts";

const secret = btoa("test-webhook-secret-with-32-bytes!");
const config: Record<string, string> = {
  MAILTRAP_API_TOKEN: "test-private-provider-token",
  SEND_EMAIL_HOOK_SECRET: `v1,whsec_${secret}`,
  SUPABASE_URL: "https://project.example.test",
  MAILTRAP_FROM_EMAIL: "club@example.test",
  MAILTRAP_MODE: "sandbox",
  MAILTRAP_INBOX_ID: "123",
};
function event(action = "recovery") {
  return {
    user: { email: "member@example.test", new_email: "new@example.test" },
    email_data: {
      email_action_type: action,
      token_hash: "server-issued-hash",
      redirect_to: "http://127.0.0.1:8080/reset-password",
    },
  };
}
function signed(payload: unknown, date = new Date()): Request {
  const body = JSON.stringify(payload);
  const id = "test-auth-event";
  return new Request(
    "https://project.example.test/functions/v1/auth-email-mailtrap",
    {
      method: "POST",
      body,
      headers: {
        "webhook-id": id,
        "webhook-timestamp": `${Math.floor(date.getTime() / 1000)}`,
        "webhook-signature": new Webhook(secret).sign(id, date, body),
      },
    },
  );
}
function setup(overrides: Record<string, string> = {}, reply?: () => Response) {
  const calls: { url: string; body: Record<string, any>; headers: Headers }[] =
    [];
  const settings = { ...config, ...overrides };
  const handler = createMailtrapHook({
    env: (key) => settings[key],
    fetch: (async (url, init) => {
      calls.push({
        url: String(url),
        body: JSON.parse(String(init?.body)),
        headers: new Headers(init?.headers),
      });
      return reply?.() ??
        Response.json({ success: true, message_ids: ["accepted-test-id"] });
    }) as typeof fetch,
  });
  return { handler, calls };
}

Deno.test("unsigned callers cannot turn the hook into a mail relay", async () => {
  const { handler, calls } = setup();
  const result = await handler(
    new Request("https://example.test", {
      method: "POST",
      body: JSON.stringify(event()),
    }),
  );
  assert.equal(result.status, 401);
  assert.equal(calls.length, 0);
});
Deno.test("tampered and expired signatures are rejected before contacting Mailtrap", async () => {
  const { handler, calls } = setup();
  const original = signed(event());
  const tampered = new Request(original.url, {
    method: "POST",
    headers: original.headers,
    body: JSON.stringify(event("signup")),
  });
  assert.equal((await handler(tampered)).status, 401);
  assert.equal(
    (await handler(signed(event(), new Date(Date.now() - 600000)))).status,
    401,
  );
  assert.equal(calls.length, 0);
});
Deno.test("sandbox recovery uses a real Supabase verification link and server token", async () => {
  const { handler, calls } = setup();
  assert.equal((await handler(signed(event()))).status, 200);
  assert.equal(calls[0].url, "https://sandbox.api.mailtrap.io/api/send/123");
  assert.equal(
    calls[0].headers.get("Authorization"),
    "Bearer test-private-provider-token",
  );
  assert.equal(calls[0].body.to[0].email, "member@example.test");
  const text = calls[0].body.text as string;
  const link = new URL(
    text.split("\n\n").find((line) => line.startsWith("https://"))!,
  );
  assert.equal(link.origin, "https://project.example.test");
  assert.equal(link.pathname, "/auth/v1/verify");
  assert.equal(link.searchParams.get("token"), "server-issued-hash");
  assert.equal(link.searchParams.get("type"), "recovery");
  assert.equal(
    link.searchParams.get("redirect_to"),
    "http://127.0.0.1:8080/reset-password",
  );
  assert.ok(
    !JSON.stringify(calls[0].body).includes("test-private-provider-token"),
  );
});
Deno.test("live delivery selects the transactional API without duplicating to sandbox", async () => {
  const { handler, calls } = setup({ MAILTRAP_MODE: "live" });
  assert.equal((await handler(signed(event("signup")))).status, 200);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].url, "https://send.api.mailtrap.io/api/send");
  assert.ok(calls[0].body.text.includes("type=signup"));
});
Deno.test("secure email change sends the correct token hashes to both addresses", async () => {
  const { handler, calls } = setup();
  const payload = {
    ...event("email_change"),
    email_data: {
      ...event("email_change").email_data,
      token_hash: "new-address-hash",
      token_hash_new: "old-address-hash",
    },
  };
  assert.equal((await handler(signed(payload))).status, 200);
  assert.equal(calls.length, 2);
  assert.equal(calls[0].body.to[0].email, "member@example.test");
  assert.ok(calls[0].body.text.includes("token=old-address-hash"));
  assert.equal(calls[1].body.to[0].email, "new@example.test");
  assert.ok(calls[1].body.text.includes("token=new-address-hash"));
});
Deno.test("email-change notifications go to the previous address without reset tokens", async () => {
  const { handler, calls } = setup();
  const payload = {
    ...event("email_changed_notification"),
    email_data: {
      email_action_type: "email_changed_notification",
      old_email: "old@example.test",
    },
  };
  assert.equal((await handler(signed(payload))).status, 200);
  assert.equal(calls[0].body.to[0].email, "old@example.test");
  assert.ok(!calls[0].body.text.includes("/auth/v1/verify"));
  assert.ok(!calls[0].body.text.includes("ignore this email"));
});
for (const providerFailure of ["http", "rejected", "network"]) {
  Deno.test(`Mailtrap ${providerFailure} failures never return a false delivery success`, async () => {
    const { handler } = setup({}, () => {
      if (providerFailure === "network") {
        throw new Error("private provider diagnostic");
      }
      return providerFailure === "http"
        ? new Response("private provider diagnostic", { status: 403 })
        : Response.json({ success: false });
    });
    const result = await handler(signed(event()));
    assert.equal(result.status, 502);
    assert.ok(!(await result.text()).includes("private provider diagnostic"));
  });
}
Deno.test("missing server configuration and invalid signed payloads send nothing", async () => {
  const missing = setup({ SEND_EMAIL_HOOK_SECRET: "" });
  assert.equal((await missing.handler(signed(event()))).status, 500);
  assert.equal(missing.calls.length, 0);
  const { handler, calls } = setup();
  assert.equal(
    (await handler(
      signed({
        user: { email: "member@example.test" },
        email_data: { email_action_type: "recovery" },
      }),
    )).status,
    422,
  );
  assert.equal((await handler(signed(event("unknown-action")))).status, 422);
  assert.equal(calls.length, 0);
});
