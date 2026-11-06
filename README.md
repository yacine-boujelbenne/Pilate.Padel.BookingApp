# Fléx Pilates & Padel

Flutter booking application for members, coaches and administrators, using Supabase, Provider and GoRouter.

The [audit and design review](docs/design-review/README.md) includes the screen inventory, visual direction and captured Flutter screen gallery. Current implementation and remaining release checks are tracked in the [implementation report](docs/REDESIGN-IMPLEMENTATION.md).

## Run locally

Use Flutter **3.38.4 / Dart 3.10.3 or newer**, matching the minimums already required by the lockfile. A compatible SDK was installed beside this checkout at `../.tooling/flutter`; it does not change the machine's global Flutter installation.

Fill the ignored local `.env` file with your Supabase client configuration:

```dotenv
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

The full `.env` stays local and is never bundled. `scripts/flutterw` generates `.env.client` containing only `SUPABASE_URL` and `SUPABASE_ANON_KEY`; Flutter loads this public asset. Mailtrap API tokens and other server credentials are excluded. No development credentials are committed. Firebase configuration is optional for local UI work; remote push delivery requires the actual platform setup.

For password-reset email delivery, see [Password recovery setup](docs/PASSWORD-RECOVERY-SETUP.md). Hosted Supabase email delivery and allowed callback URLs are configured in its dashboard, separately from this client `.env`.

The requested Mailtrap HTTP API integration is a signed Supabase Send Email hook, with Sandbox testing and live sending modes. It is deployed and currently uses live sending through the account's demo sender. Mailtrap reports a real recovery email delivered to the registered Mailtrap recipient; initial Sandbox testing also verified the app request and callback to the password form. The demo sender permits only the registered account email—other member destinations need an owned, verified sending domain. See [Mailtrap API deployment and activation](docs/MAILTRAP-API-INTEGRATION.md). Supabase generates the authentication links and provider tokens stay server-side.

```sh
./scripts/flutterw pub get
./scripts/flutterw run
```

The wrapper uses Flutter on PATH or the compatible SDK at `../.tooling/flutter`. Use the wrapper after editing `.env`, including when building releases. To use Flutter directly, first run `python3 scripts/prepare_client_env.py` to refresh the public asset.

For the browser preview, use `./scripts/preview-web`. It builds the app and serves only `build/web` at `http://127.0.0.1:8080`, with recovery-route support. This keeps private project files outside the served directory. Flutter's development web server can expose project files directly; use this confined preview when keeping private tool tokens in the project's `.env`.

## Verify

The Rive runtime needs its native test library once on a new test machine. On Linux:

```sh
dart run rive_native:setup --platform linux
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Before these checks, prepare `.env.client` with `python3 scripts/prepare_client_env.py` or use `./scripts/flutterw` in place of `flutter`. Verify the environment allowlist with `python3 -m unittest discover -s scripts -p 'test_*.py'`.

Use Rive's corresponding `macos` or `windows` setup target on those hosts. Normal platform builds also perform runtime setup. The existing Android/iOS release signing, Firebase and backend deployment configuration must be supplied separately.

Tests exercise reservation identity/status, booking eligibility, stale date responses, role navigation, responsive controls, member/staff layouts and the actual bundled Rive asset. Test fixtures live only in `test/support/`; production screens continue to use Supabase.

Optional review captures use actual Flutter widgets with explicitly illustrative test data:

```sh
flutter test test/screen_review_test.dart --dart-define=CAPTURE_REVIEW=true
```

Captures are written outside the repository to `../design-review/implementation/` at 390 and 1200 logical pixels.

## Redesign scope

The original mint/sage palette is preserved, with locally bundled Manrope/Inter, licensed campaign photography, shared surfaces/forms/navigation, accessible feedback and reduced-motion support. Member reservation/waitlist journeys and staff operational views use the same foundations.

The new member notification inbox reads the existing Supabase notification records, supports marking them read, and subscribes to changes. Actual delivery still depends on configured server writes, RLS/publication and any push/email infrastructure; an inbox animation does not prove external delivery.

Payment choices, payment payloads and validation behavior are retained. Payment processing improvements remain a final, deferred work package. Chat, SMS/email delivery, rescheduling, and court inventory are future integrations; no paid provider or new backend schema is introduced by this redesign.

Visual asset sources and license links are bundled and available through **Settings → About Fléx & credits → Licenses**. The Rive success asset is “Success Check” by guidorosso, CC BY 4.0. Campaign photos are decorative, not photographs of the booked facility.
