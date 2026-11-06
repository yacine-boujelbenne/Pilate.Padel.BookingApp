# Mailtrap API authentication emails

The Java example uses Mailtrap's transactional HTTP API. Flutter remains Dart, and Supabase remains responsible for creating and verifying authentication tokens. The equivalent integration is a Supabase **Send Email hook** implemented in `supabase/functions/auth-email-mailtrap/` that calls Mailtrap with server-side `fetch`. No Java runtime or client-side Mailtrap SDK is needed.

## Implemented behavior

- Sandbox mode captures test mail at `sandbox.api.mailtrap.io/api/send/{inbox_id}`.
- Live mode sends to actual recipients through `send.api.mailtrap.io/api/send`.
- One mode is selected explicitly; emails are not duplicated to both modes and a failed sandbox request never silently falls back to live delivery.
- Signup, recovery, invitations and sign-in links use Supabase's supplied token hashes and its `/auth/v1/verify` endpoint. Verification codes, secure email changes and security notifications are also handled. Enabling this hook does not invent new profile-update notification triggers; it handles events Supabase emits.
- The hook verifies Standard Webhooks signatures and their timestamp before contacting Mailtrap. It cannot be called as an unauthenticated email relay.
- Private tokens stay in Edge Function secrets. The existing Flutter calls to `signUp`, `resetPasswordForEmail` and `updateUser` are retained.
- Provider rejection, timeout, invalid signatures and malformed payloads fail explicitly. HTTP 200 with `success: false` is not treated as delivery success. Provider responses, tokens and recipient addresses are not logged.
- Multi-address secure email changes have no cross-provider transaction: one address may receive a message before the other fails. No exactly-once delivery guarantee or automatic application retry is claimed.

## Prepared local configuration

Run from the repository root:

```sh
python3 scripts/prepare_mailtrap_hook.py --mode sandbox
```

This reads the private `API_TOKEN` or `MAILTRAP_API_TOKEN` from `.env`, retrieves the sandbox ID when unambiguous, and writes ignored `.env.mailtrap-hook`. It preserves an existing hook signing secret when rerun. The file is never a Flutter asset and the confined preview server blocks it.

For an explicit sandbox transport check:

```sh
python3 scripts/check_mailtrap_sandbox.py
```

This captures one clearly labeled integration message inside the sandbox, addressed to a reserved `.test` mailbox. It sends no real email and does not simulate a successful account verification or password reset.

This check succeeded against the owner's sandbox using the supplied token. An initial Python request returned a non-JSON HTTP 403; the request with explicit JSON headers and an application User-Agent was accepted. The same headers are configured in the Edge Function. This proves API capture, not a deployed Supabase authentication flow or live inbox delivery.

## Hosted activation — completed for this project

The prepared function and private secrets are deployed to the configured Supabase project. The hosted Send Email hook is now enabled in **live** mode with the matching signing secret and the account's permitted demo sender, `hello@demomailtrap.co`. Anonymous requests were verified to receive HTTP 401 from the signature validator. The four explicit preview callbacks (`127.0.0.1` and `localhost`, login and reset-password) were added to the hosted allowlist while preserving existing redirect entries. Email confirmation remains required; SMTP, database schemas and RLS were not changed.

After the owner requested delivery to the actual destination, a live transport test and a real Supabase password-recovery request both produced messages whose Mailtrap delivery logs show **delivered** to the registered Mailtrap recipient. The live recovery link was left unopened for the owner and no password was changed. Provider delivery means recipient-server acceptance, not a guarantee of inbox placement; check spam/junk too. The previous Sandbox configuration is retained privately in `.env.mailtrap-hook.sandbox` for explicit testing-mode restoration.

The account currently has only the demo sending domain. That domain permits delivery only to the email address registered with Mailtrap. It does not support arbitrary club-member recipients. Verify an owned sending domain and configure its permitted From address before testing other members or treating the mail setup as production-ready.

### Delivery timing check

A fresh live Supabase recovery request was timed after activation: HTTP 200 returned in **1.735 seconds** (local monotonic measurement). Mailtrap reported delivery **0.975 seconds** after its own send timestamp, approximately **2.559 seconds** after the request began when comparing recorded timestamps. These are observations of one successful request, not a latency guarantee. The reset link was not opened during the timing check.

An earlier first live request had approximately 42 seconds before Mailtrap's send timestamp; the underlying cause was not established. Local/server clock comparisons showed roughly one second of offset, insufficient to explain that earlier difference. The fresh request did not reproduce it. No artificial send delay or application queue exists in the hook, and no speculative cron, paid service, weakened auth check or transport migration was introduced. Demo/provider availability, cold starts and recipient-server processing can still vary.

The initial Sandbox verification used the actual running Flutter screen: keyboard entry and **Send reset link** produced the inbox acknowledgement; a new **Reset your Fléx password** email arrived in Mailtrap; following its real Supabase link in the same browser opened **New password** with **Update password** available. The owner's password was not changed. That Sandbox test link was consumed; the subsequent live recovery email described above was not opened.

The automated browser's recovery session was signed out with local scope after verification. Other user sessions were not signed out. The temporary local verification URL was removed; tokens and recovery URLs were not printed in the verification output.

The latest Supabase CLI (3.0.0) rejected the repository's legacy local `[inbucket]` configuration. Deployment therefore ran from an isolated temporary workspace containing only this function, its lock/config files and a minimal function configuration. The existing local configuration was not migrated. CLI 3 uses `--remote=PROJECT_REF` in place of the deprecated `--project-ref` argument. The commands below describe the conventional CLI deployment; account for this compatibility difference when repeating them with CLI 3.

Local code and a valid Mailtrap token do not update hosted Supabase. Supabase management access or a signed-in Supabase CLI session is required to deploy the function and set its secrets. A Mailtrap token and the public Supabase anon key cannot perform those operations.

1. Sign in to the Supabase CLI, then use the project ref corresponding to `.env`'s Supabase URL:

```sh
npx supabase login
npx supabase secrets set --project-ref YOUR_PROJECT_REF --env-file .env.mailtrap-hook
npx supabase functions deploy auth-email-mailtrap --project-ref YOUR_PROJECT_REF --no-verify-jwt --use-api
```

2. In **Supabase Dashboard → Authentication → Hooks → Send Email**, choose the HTTP hook and set its URL to `https://YOUR_PROJECT_REF.supabase.co/functions/v1/auth-email-mailtrap`.
3. Set the hook's signing secret to the `SEND_EMAIL_HOOK_SECRET` value in `.env.mailtrap-hook`, without the dotenv quote delimiters. If the dashboard instead generates the secret, replace the local value with that exact secret and upload the secrets again. The function and Auth must use the same secret.
4. Enable and save the Send Email hook. Keep the Email provider enabled. Supabase then uses the hook instead of SMTP for auth emails. No existing tables, RLS or booking/payment functions need to change.
5. Allow `http://127.0.0.1:8080/reset-password` and `http://127.0.0.1:8080/login` in Authentication URL Configuration for this preview. Add the corresponding `localhost` URLs only if using that origin. Preserve the production and mobile callback URLs already in use.
6. From the real app, request a reset email once. Open its link from the Sandbox in the same browser where the PKCE request began, change the password, then verify sign-in. Test signup verification and any enabled account-change notification events too.

The new function alone has `verify_jwt = false` because Supabase Auth calls it with a signed webhook rather than a member JWT. Signature verification is mandatory in the handler. Existing functions retain their current settings.

The hosted request-to-Sandbox-to-reset-form check and live delivery to the permitted demo recipient have succeeded. Password update/sign-in using an owner-chosen password, inbox placement and delivery to arbitrary member addresses remain separate checks.

## Switching to actual delivery later

```sh
python3 scripts/prepare_mailtrap_hook.py --mode live --from-email no-reply@YOUR_VERIFIED_DOMAIN
npx supabase secrets set --project-ref YOUR_PROJECT_REF --env-file .env.mailtrap-hook
```

Use a token authorized for transactional sending and a permitted sender domain. `hello@demomailtrap.co` in the Java example is a demonstration sender with Mailtrap's trial recipient restrictions; it is not a universal production sender. Sandbox testing proves capture, not real inbox delivery. Do not disable TLS, account verification or signature checking to work around provider errors.

## Verification

```sh
cd supabase/functions/auth-email-mailtrap
npx --yes deno check index.ts
npx --yes deno test handler_test.ts
```

Dependencies are pinned in `deno.lock`; `standardwebhooks@1.0.0` is the only added runtime library and lives on the server. Flutter gains no Mailtrap dependency.

References: [Supabase Send Email hook](https://supabase.com/docs/guides/auth/auth-hooks/send-email-hook), [Mailtrap transactional API](https://docs.mailtrap.io/developers/email-sending), [Mailtrap Sandbox](https://docs.mailtrap.io/email-sandbox/overview).
