# Fléx redesign — implementation and verification

Branch: `design/premium-mint-sage`. Started 5 November 2026, verification continued 6 November 2026. Original architecture and backend contracts retained. Payment processing improvements are deferred at the user's request.

## Implemented foundations

- Original mint `#EBF3EE`, sage `#7A9082`, sage-dark `#5A6E62`, white and charcoal `#2C3A33`; complementary forest, ivory and a restrained court tint.
- Bundled Manrope and Inter with licenses; explicit Manrope variable-font weights, readable secondary text, centralized spacing/radii/shadows/motion and themed Flutter controls.
- Shared page constraints, adaptive statistics, surfaces, headings, scrollable sheets, loading/skeleton/error/empty states, flexible detail rows and a rounded member navigation dock.
- Accessible button targets, visible field labels, password visibility, keyboard/autofill support, and reduced-motion handling. Layout checks include narrow screens and 200% text for booking controls/navigation.
- Licensed, locally bundled campaign photos with placeholders and credits. Actual avatar URLs use the existing cached-network-image package with initials fallback. No fake facility or coach images.
- Rive Marketplace “Success Check” by guidorosso (CC BY 4.0), using stable Rive Flutter 0.14.11. Asset loading, actual rendering, one-shot playback, cleanup and reduced-motion fallback are covered. No editor subscription purchased and no binary branding restrictions bypassed.

## Member journey

- Home: time-aware greeting, upcoming reservation with genuine joined session identity, stable seven-day date strip/full date picker, date-local loading/errors, availability and waitlist states. Schedule comes before the campaign image so booking controls are easier to reach.
- Reservation cards/history: actual titles and session times; active/history/cancelled presentation instead of ID fragments or treating cancelled reservations as “Done.” Missing historical relationships retain the booking with an honest fallback.
- Shared booking review and waitlist presentation across Home and coach details. Full/elapsed/pending/cancelled eligibility and existing reservations are checked consistently. Duplicate booking submissions are guarded; the existing payment choices and insert/payment fields are retained.
- Cancellation and waitlist leaving require confirmation and show in-flight/error feedback. Joining exposes the real server-assigned queue position after insertion rather than guaranteeing a client preview.
- Explore: accurate coach/speciality search, real-avatar support, relevant campaign imagery and retry/empty states. Coach details use the shared session cards and booking/waitlist handoffs.
- Profile: cached activity future with retry, genuine activity counts, removal of the tier-derived “Avg rating” presentation, and visible links to waitlists and club updates.
- Reservation confirmation: genuine session details, Rive success gesture and a link to bookings. The existing payment processing behavior remains deferred.
- New `/member/notifications`: reads the existing Supabase notification table, marks owned records read, subscribes to authenticated member changes and supports refresh/error/empty states. No mocked notifications or outbound provider was added.

## Authentication and staff

- Branded, scrolling sign-in with appropriate input handling; existing registration/recovery/reset screens inherit the new form system, page constraints and introductory hierarchy. Password whitespace is preserved during sign-in.
- Existing role URLs/redirects retained. Added staff guarding to the shared attendee route and role-aware account/settings fallbacks. Splash routes members correctly and cancels its timer when disposed.
- Account-scoped providers are recreated when the authenticated user changes; old caches/realtime channels are disposed. Shared ChangeNotifier lifecycle handling prevents late requests notifying a disposed account subtree.
- Coach portal: dated schedule rows, responsive metrics/actions, consistent chart styling, schedule loading/error feedback, existing proposals and approvals retained. Session creation uses native date/time pickers.
- Admin dashboard: coherent metrics/member/coach sections, useful refresh errors instead of raw backend diagnostics, blocked members remain reachable, and coach Edit now saves existing profile fields. Member/coach collections refresh after mutations.
- Admin session management: dates, progress/error feedback, wrapped action groups, guarded actions and session-cancellation confirmation. Existing create/approve/reject/edit/cancel contracts preserved.
- Session editing and member details load their records directly by ID, so they do not depend on having visited a parent list. Member access changes have confirmation and accurate status, including restore access.
- Attendee roster uses the shared palette and a visible back control. It remains a read-only roster; no pretend attendance or messaging action is introduced.
- Platform display names/PWA metadata use Fléx. Application IDs, signing, deep-link contracts, schemas, RLS and existing Edge Functions are unchanged. The requested new email hook is documented separately below.

## Technical scope

Read queries join existing session/coach/studio relationships without `inner` filtering away historical bookings. Daily queries use local calendar boundaries converted to UTC; stale previous-date responses cannot replace the latest day. Existing authentication, booking inserts, cancellation updates, payment choices and payment validation semantics are preserved.

Flutter adds only Rive and its two transitive packages; existing locked package versions were retained. The separately requested Mailtrap API hook uses the server-only `standardwebhooks@1.0.0` library with its own lockfile. Manifest SDK minimums match the Dart 3.10.3 / Flutter 3.38.4 requirements already present in the original lockfile. The SDK was installed locally beside the app, not globally.

The user populated the ignored local `.env`. After a Mailtrap token was added, startup was updated to use generated `.env.client`, which allowlists only public Supabase client configuration. The full `.env` and retrieved `.env.smtp` stay outside Flutter assets. Use `scripts/flutterw` to regenerate the public asset before running or building. No credentials are committed. Supabase connectivity and recovery delivery were verified; authenticated role/booking queries and policies still require their broader live regression pass.

## Verification

Baseline was run against an untouched worktree: two existing lint issues plus the absent `.env` asset warning. Those were recorded separately from implementation failures.

Local results after the authentication/API follow-up: formatting clean, Flutter analysis reports no issues and all 26 Flutter tests pass. The web release build succeeds. `git diff --check` is clean. Database schema, RLS, migrations and existing Edge Functions are unchanged. The new signed email hook was deployed and enabled in the configured Supabase project after the owner supplied management access. Preview callback URLs were added without removing existing allowlist entries.

The environment follow-up also passes four Python checks covering the public-configuration allowlist, malformed values, private-file blocking, symlink escape prevention and SPA callback routing. Live HTTP checks confirm that private environment files return 404, the public asset contains exactly the two allowed Supabase keys, and the rebuilt sign-in screen renders. The Mailtrap hook passes ten tests for signatures, expired/tampered requests, real Supabase link construction, both modes, secure email changes and provider failures. Hosted verification now confirms: the actual app reset request succeeds, the real recovery email appears in Mailtrap Sandbox, and its link opens the new-password form in the same browser. The owner's password was not changed, and live recipient delivery remains a separate integration check.

At the owner's subsequent request, the deployed hook was switched to live sending. A transport test and a real Supabase password-recovery message were confirmed **delivered** in Mailtrap's live delivery logs. The latter link was left unopened for the owner. Current live delivery is restricted to Mailtrap's demo-recipient address until an owned sending domain is verified; general member delivery and inbox placement are not established by this check.

Registration now has an explicit back control and an “Already have an account? Log in” link below the primary action. Recovery and new-password screens share the same small login control. Route tests exercise all three links and the registration back action.

Verification covers:

- Formatting and static analysis.
- Model tests for joined identity, status, hidden relationships and booking eligibility.
- A real local HTTP test proving stale date responses cannot overwrite newer selection.
- Component tests for full/booked actions, 320 px / 200% text and reduced motion.
- Actual Rive file loading and motion-enabled rendering with its native test library.
- GoRouter role guards for member/coach/admin/signed-out users.
- Password recovery HTTP 500/429/200 responses with PKCE storage, safe error display, account-neutral request acknowledgement, email validation and repeated-submit prevention. These automated tests use local responses and send no external emails; live recovery checks were performed separately as described above.
- Actual member Home, bookings, waitlists, login, coach and admin widget rendering at 390 and 1200 logical pixels, with fixtures isolated under `test/support/`.
- Web release compilation, with live recovery request/delivery/callback checks tracked separately above.

Review captures and an offline gallery are archived in `docs/design-review/implementation/`. The capture test writes new images to the local sibling `../design-review/implementation/` directory. The committed review images contain illustrative test data and must not be described as screenshots of live member accounts.

## Remaining integration/release work

- Complete the real member/coach/admin regression pass using the supplied configuration. The recovery request, Sandbox delivery and callback to the password form have been verified separately.
- Verify deployed RLS, historical-session visibility, waitlist ordering/publication and notification creation/delivery. The source-level backend risks in the audit are unchanged; no policy/security fixes were silently bundled into a UI change.
- Configure and test push/email/SMS delivery separately. Existing Firebase initialization is retained; Supabase inbox updates are not proof of background delivery. Chat and new messaging schemas remain future work.
- Payment gateway, payment integrity, refunds, receipt/payment-specific improvements and any atomic rescheduling remain deferred.
- Native Android/iOS builds, signing, device performance/screen-reader checks and full live-data visual review require the relevant platform environment and accounts. Web compilation and fixture tests alone do not establish production readiness.

See the repository README for reproducible commands, native Rive test setup and optional screenshot capture.
