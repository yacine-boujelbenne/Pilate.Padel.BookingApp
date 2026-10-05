# Review and rollout

## Preview without credentials

```sh
flutter pub get
# The original pubspec declares .env as an asset, including in preview builds.
touch .env
flutter run -t lib/preview.dart
```

This is an explicit design preview with labelled sample data, separate from the
production `main.dart`. It demonstrates date selection, card styling, breathing
artwork, processing, confirmation and navigation. Explore shows an empty state;
Profile demonstrates placeholders. It does not access Supabase or collect money.

The GitHub Actions `design-preview-web` artifact contains a static preview build.
Serve its extracted folder using a local HTTP server to view it in a browser.

## Verification

```sh
flutter analyze --no-fatal-infos
flutter test
dart run test/model_check.dart
```

The database CI job uses an isolated PostgreSQL instance and minimal Auth fixtures
before applying the migrations and `test/database/reservation_security.sql`.
Never apply `test/database/mock_auth.sql` to a Supabase project.
The SQL scenarios cover role escalation, sensitive field mutation, payment
fabrication, idempotent retries, full/past sessions, price snapshots, repeated
cancellation/rebooking, queue resequencing, ownership, cash collection, atomic edit
failure, coach permissions, notifications, historical reads and blocked accounts.
A real concurrent request test is still required on staging; the offline suite
checks transactional behavior but does not emulate multiple database clients.

## Deployment order

1. Back up and test against staging using the actual deployed schema. Confirm
   migration history matches this repository, especially the legacy filenames.
2. Audit existing privileged profiles. Old signup metadata could assign roles;
   this migration prevents new escalation but deliberately does not revoke real
   staff roles automatically.
3. Reconcile historical payments and quotes. Existing 'paid' rows are not proof
   of an online payment. Quote backfill uses the current session price.
4. Check for duplicate active reservations, RLS advisor findings and unexpected
   column grants before applying the new migration.
5. Apply `20261005170545_secure_reservation_flow.sql` to staging and run real
   member/coach/admin flows. Test simultaneous final-place requests and retries.
6. Deploy `create-coach-account` together with the app; it now checks blocked
   admins and uses cryptographic randomness for temporary passwords.
7. Deploy the migration before the app that calls its new RPCs. The protected
   direct-write paths make old clients incompatible: use a coordinated release
   or maintenance window rather than deploying the migration days earlier.
8. Run database advisors and verify in-app cancellation notifications and RLS
   joins against real accounts before production release.

No production database migration or Edge Function deployment is performed by
this pull request. Roll back the application and database together. Do not remove
write protections simply to let an old client fabricate payment status again.

## Device checks

Review 320 px phone, tablet and desktop layouts; large text; screen-reader labels;
reduced motion; offline failures; slow submission; background/foreground; logout
and signing into another account. Profile/admin layouts inherited from the
original app need separate device review. Confirm sustained animation performance
on a modest Android phone before release.
