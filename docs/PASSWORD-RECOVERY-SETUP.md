# Password recovery delivery

The requested API-based alternative is deployed and enabled as a signed Supabase Send Email hook. Initial Sandbox testing verified the Flutter request, captured email and callback to the new-password form. It was then switched to live mode at the owner's request: Mailtrap delivery logs confirm **delivered** for a real Supabase recovery email to the registered Mailtrap recipient. The latest live link was left unopened and the owner's password was not changed. The account's demo sender only supports that registered recipient; other member addresses require an owned, verified sending domain. See [Mailtrap API integration and hosted activation](MAILTRAP-API-INTEGRATION.md). SMTP settings are preserved; the enabled hook now handles authentication email delivery.

The observed response was HTTP 500 / `unexpected_failure` / “Error sending recovery email.” The request reached Supabase Auth; the screenshot does not identify the underlying SMTP, template or hook failure. The public client key cannot read hosted Auth logs or change mailer settings.

The owner initially confirmed using Supabase's default email service, then reported configuring Mailtrap Sandbox. Auth logs supplied afterward identify two failures: an earlier SMTP `535 5.7.8 Authentication failed`, followed by `tls: first record does not look like a TLS handshake` on the latest `/recover` request. The current failure is a TLS/protocol mismatch; the earlier one indicates rejected SMTP credentials. The hosted SMTP field values remain unverified without an authenticated project-management connection.

### Confirmed diagnostic and correction

The Mailtrap API token supplied in the local `API_TOKEN` variable was accepted by Mailtrap's read API. It grants access to one sandbox and its SMTP credentials. The exact sandbox SMTP settings were saved in ignored `.env.smtp` for the owner to copy into hosted Supabase Custom SMTP settings. A subsequent certificate-validated STARTTLS connection and SMTP login on port 587 succeeded with those credentials (SMTP 235). No email send, hosted Supabase configuration update or new authentication hook was performed. Mailtrap API access does not confer Supabase management access and an API token is not the sandbox SMTP password.

The original Flutter asset declaration bundled the entire `.env`; a running local build was confirmed to include `API_TOKEN`. That build was stopped and obsolete full-environment assets removed. Flutter now bundles only generated `.env.client`, with an explicit allowlist of the public Supabase URL and anon key. Keep using `scripts/flutterw` to refresh this asset before running/building. Flutter's development server also served `/.env` and `/.env.smtp` directly from the project directory, so the local browser preview was switched to `scripts/serve_web.py`, confined to the compiled `build/web` directory. Live HTTP checks now return 404 for both private files and their asset paths, while the public client asset and recovery callback route work. Use `scripts/preview-web` for subsequent browser previews. Replace the Mailtrap token that was included in the previous local build; update the local `.env` with the replacement. No token values are committed or printed in diagnostics.

Set the hosted project's Custom SMTP host to `sandbox.smtp.mailtrap.io` and port to **587** (STARTTLS), then copy the **same sandbox's SMTP username and password** from Mailtrap's Integration tab and save. Port **2525** with STARTTLS is an alternative. Avoid implicit TLS/port 465 for this configuration: the supplied handshake error is consistent with an implicit-TLS client receiving an ordinary SMTP greeting. Keep certificate validation enabled.

Local read-only connection checks verified certificate-validated STARTTLS handshakes to Mailtrap Sandbox on both 587 and 2525. No SMTP authentication or email send was attempted. These checks establish endpoint protocol compatibility from the development computer, not successful authentication or connectivity from Supabase's servers.

After saving, retry once in the running app and check the Mailtrap Sandbox inbox. A new `535` means the SMTP username/password still need correction. Hosted SMTP changes do not require restarting Flutter. The Auth deprecation notices in the supplied logs are separate from these delivery failures.

Supabase's default email service is intended for testing, only sends to project organization team addresses, and currently limits sending to two messages per hour. These restrictions should not be assumed to explain a failure after switching to custom SMTP.

For Mailtrap Sandbox, copy the host (`sandbox.smtp.mailtrap.io`), supported port, and the specific sandbox's SMTP username/password from its Integration tab into the **same hosted Supabase project's Custom SMTP settings**, enable the custom SMTP configuration, and save it. Configuring a Mailtrap inbox alone does not configure Supabase. SMTP credentials differ from Mailtrap website login details and API tokens. Mailtrap Sandbox captures emails in its test inbox; it does not deliver them to members' personal inboxes. See [Mailtrap SMTP setup](https://docs.mailtrap.io/email-sandbox/setup).

## Hosted project setup

1. Open **Supabase Dashboard → Logs → Auth**. Inspect the failed `/recover` request at the time of the failure. The internal error distinguishes SMTP rejection, sender verification, template/hook failures and other backend problems. Avoid sharing tokens or private account data from logs.
2. For recovery emails to ordinary members, configure **Authentication → Email → SMTP Settings** with a working SMTP relay, its verified sender, host, port, username and password. Supabase accepts standard SMTP, including an existing relay or an independently hosted open-source mail server. No paid email SDK is required in Flutter. Operating a public mail server still requires reachable infrastructure and sender/domain configuration; open-source software alone does not supply free internet delivery.
3. Keep SMTP credentials in Supabase's server-side settings. The local `.env` can contain private tool credentials because it is no longer a Flutter asset; generated `.env.client` is the public asset and contains only the Supabase URL/client key. `.env.smtp` is also local and ignored. These files do not configure hosted Auth automatically.
4. Under **Authentication → URL Configuration**, allow the exact development redirect `http://127.0.0.1:8080/reset-password`. If accessing the app as `localhost`, also allow `http://localhost:8080/reset-password`. These are separate origins. Set the production Site URL and allow the production reset URL before deployment. The app currently uses Flutter's default hash routing. Preserve Supabase's recovery query/fragment when opening the link; the complete callback and password update still need a live end-to-end check after delivery is configured.
5. Check **Authentication → Email Templates → Reset Password**. Preserve the built-in confirmation link or a correctly configured recovery-token template. A malformed custom template or failing Send Email hook can also break delivery.
6. After fixing the server settings, request one reset email from the app, open the link in the intended browser/device, and verify that the new password works. Avoid repeated requests while troubleshooting rate limits.

The repository `supabase/config.toml` describes local Supabase development; editing it alone does not update this hosted project's SMTP or redirect allow-list. No hosted settings or outbound emails were changed during the UI fix.

## Application behavior

- Keep Supabase's existing `resetPasswordForEmail` flow and account checks.
- Validate the email before requesting; disable repeat submissions while awaiting the response.
- Show a service failure independently from email validation. Provider exceptions, JSON and internal details never appear on recovery screens.
- Show an account-neutral inbox state only after a successful API response. This acknowledges the request and does not claim confirmed email delivery.
- Map throttling, connectivity, invalid/expired sessions and password-policy failures to readable guidance.

References: [Supabase SMTP](https://supabase.com/docs/guides/auth/auth-smtp), [Auth 500 diagnostics](https://supabase.com/kb/troubleshooting/resolving-500-status-authentication-errors-7bU5U8), [redirect configuration](https://supabase.com/docs/guides/auth/redirect-urls).
