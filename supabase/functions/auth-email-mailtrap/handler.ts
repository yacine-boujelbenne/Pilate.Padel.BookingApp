import { Webhook } from "npm:standardwebhooks@1.0.0";

type EmailData = {
  email_action_type: string;
  token?: string;
  token_hash?: string;
  token_new?: string;
  token_hash_new?: string;
  redirect_to?: string;
  site_url?: string;
  old_email?: string;
};
type AuthEmail = {
  user: { email?: string; new_email?: string };
  email_data: EmailData;
};
type Message = {
  to: string;
  subject: string;
  title: string;
  text: string;
  link?: string;
  code?: string;
};
type Dependencies = {
  env: (name: string) => string | undefined;
  fetch?: typeof fetch;
  log?: (message: string) => void;
};

function required(value: unknown): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new Error("Missing email data");
  }
  return value;
}

function verifyLink(base: string, data: EmailData, hash: unknown): string {
  const link = new URL("/auth/v1/verify", base);
  link.searchParams.set("token", required(hash));
  link.searchParams.set("type", data.email_action_type);
  const redirect = data.redirect_to || data.site_url;
  if (redirect) link.searchParams.set("redirect_to", redirect);
  return link.toString();
}

function messages(event: AuthEmail, base: string): Message[] {
  const data = event.email_data;
  const to = required(event.user.email);
  const action = required(data.email_action_type);
  if (action === "email_change") {
    const newEmail = required(event.user.new_email);
    const result: Message[] = [];
    // Supabase's secure email-change field names are reversed for compatibility.
    if (data.token_hash_new) {
      result.push({
        to,
        subject: "Confirm your email change",
        title: "A new way to stay connected.",
        text: "Confirm the email change you requested for your Fléx account.",
        link: verifyLink(base, data, data.token_hash_new),
      });
    }
    result.push({
      to: newEmail,
      subject: "Verify your new email",
      title: "Let’s confirm your new email.",
      text: "Confirm this email address for your Fléx account.",
      link: verifyLink(base, data, data.token_hash),
    });
    return result;
  }
  const actions: Record<string, [string, string, string]> = {
    signup: [
      "Verify your Fléx account",
      "Your next chapter starts here.",
      "Confirm your email to finish creating your Fléx account.",
    ],
    recovery: [
      "Reset your Fléx password",
      "Let’s get you back.",
      "Use the secure link below to choose a new password.",
    ],
    invite: [
      "Your invitation to Fléx",
      "Make room for you.",
      "Accept your invitation to join Fléx.",
    ],
    magiclink: [
      "Your Fléx sign-in link",
      "Welcome back.",
      "Use this secure link to sign in to your Fléx account.",
    ],
  };
  if (actions[action]) {
    const [subject, title, text] = actions[action];
    return [{
      to,
      subject,
      title,
      text,
      link: verifyLink(base, data, data.token_hash),
    }];
  }
  if (action === "reauthentication") {
    return [{
      to,
      subject: "Confirm it’s you",
      title: "A quick security check.",
      text: "Enter this verification code in Fléx to continue.",
      code: required(data.token),
    }];
  }
  const notifications: Record<string, string> = {
    password_changed_notification: "Your Fléx password was updated.",
    email_changed_notification: "Your Fléx email address was updated.",
    phone_changed_notification: "Your Fléx phone number was updated.",
    identity_linked_notification:
      "A sign-in method was added to your Fléx account.",
    identity_unlinked_notification:
      "A sign-in method was removed from your Fléx account.",
    mfa_factor_enrolled_notification:
      "Two-factor authentication was added to your Fléx account.",
    mfa_factor_unenrolled_notification:
      "A two-factor authentication method was removed from your Fléx account.",
  };
  if (notifications[action]) {
    return [{
      to: action === "email_changed_notification" ? data.old_email || to : to,
      subject: "Your Fléx account was updated",
      title: "An update to your account.",
      text: `${
        notifications[action]
      } If you did not make this change, contact the club.`,
    }];
  }
  throw new Error("Unsupported auth email action");
}

function escapeHtml(value: string): string {
  return value.replace(
    /[&<>"']/g,
    (character) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        character
      ]!,
  );
}

function content(message: Message): { text: string; html: string } {
  const footer = message.link || message.code
    ? "If you did not request this, you can ignore this email. Never share a reset link or verification code."
    : "If you do not recognize this update, contact the club immediately.";
  const text = [message.title, message.text, message.link, message.code, footer]
    .filter(Boolean).join("\n\n");
  const action = message.link
    ? `<p style="margin:28px 0"><a href="${
      escapeHtml(message.link)
    }" style="background:#5A6E62;color:#fff;padding:14px 24px;border-radius:12px;text-decoration:none;display:inline-block">Continue securely</a></p><p style="overflow-wrap:anywhere;font-size:12px">Or copy this link: ${
      escapeHtml(message.link)
    }</p>`
    : message.code
    ? `<p style="font-size:28px;letter-spacing:6px">${
      escapeHtml(message.code)
    }</p>`
    : "";
  return {
    text,
    html:
      `<!doctype html><html><body style="margin:0;background:#EBF3EE;color:#2C3A33;font:16px/1.6 Arial,sans-serif"><div style="max-width:560px;margin:auto;padding:36px 24px"><p style="font-size:32px;font-weight:bold">Fléx.</p><div style="background:#fff;border-radius:20px;padding:28px"><h1 style="font-size:26px;line-height:1.25">${
        escapeHtml(message.title)
      }</h1><p>${
        escapeHtml(message.text)
      }</p>${action}<p style="font-size:13px;color:#4E6057">${
        escapeHtml(footer)
      }</p></div></div></body></html>`,
  };
}

function response(status: number, message?: string): Response {
  return Response.json(
    message ? { error: { http_code: status, message } } : {},
    { status },
  );
}

export function createMailtrapHook(
  deps: Dependencies,
): (request: Request) => Promise<Response> {
  const send = deps.fetch ?? fetch;
  const log = deps.log ?? (() => {});
  return async (request) => {
    if (request.method !== "POST") return response(405, "Method not allowed");
    const token = deps.env("MAILTRAP_API_TOKEN") || deps.env("API_TOKEN");
    const secret = deps.env("SEND_EMAIL_HOOK_SECRET");
    const base = deps.env("SUPABASE_URL");
    const from = deps.env("MAILTRAP_FROM_EMAIL");
    const mode = deps.env("MAILTRAP_MODE") || "sandbox";
    const inbox = deps.env("MAILTRAP_INBOX_ID");
    if (
      !token || !secret || !base || !from ||
      !["sandbox", "live"].includes(mode) ||
      mode === "sandbox" && !/^\d+$/.test(inbox || "")
    ) {
      return response(500, "Authentication email service is not configured");
    }
    const raw = await request.text();
    if (new TextEncoder().encode(raw).length > 262144) {
      return response(413, "Request too large");
    }
    let event: AuthEmail;
    try {
      const webhook = new Webhook(secret.replace(/^v1,whsec_/, ""));
      event = webhook.verify(
        raw,
        Object.fromEntries(request.headers),
      ) as AuthEmail;
    } catch {
      return response(401, "Invalid hook signature");
    }
    let outgoing: Message[];
    try {
      outgoing = messages(event, base);
    } catch {
      return response(422, "Invalid authentication email payload");
    }
    const endpoint = mode === "sandbox"
      ? `https://sandbox.api.mailtrap.io/api/send/${inbox}`
      : "https://send.api.mailtrap.io/api/send";
    const results = await Promise.allSettled(outgoing.map(async (message) => {
      const result = await send(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          "User-Agent": "FlexAuth-Mailtrap/1.0",
        },
        redirect: "error",
        signal: AbortSignal.timeout(4000),
        body: JSON.stringify({
          from: { email: from, name: "Fléx" },
          to: [{ email: message.to }],
          subject: message.subject,
          ...content(message),
          category: "Fléx authentication",
        }),
      });
      if (!result.ok) {
        log(`Mailtrap ${mode} rejected auth email: HTTP ${result.status}`);
        throw new Error("Provider rejected authentication email");
      }
      const accepted = await result.json();
      if (accepted?.success !== true) {
        throw new Error("Provider did not accept authentication email");
      }
    }));
    if (results.some((result) => result.status === "rejected")) {
      log(`Mailtrap ${mode} auth email delivery failed`);
      return response(502, "Authentication email could not be sent");
    }
    return response(200);
  };
}
