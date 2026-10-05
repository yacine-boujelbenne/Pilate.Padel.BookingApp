# Fléx Pilates Studio

Flutter booking application with member, coach and admin flows, backed by
Supabase Auth, PostgreSQL/RLS, Realtime and Edge Functions.

The member experience includes a shared design and motion system, persistent
navigation tabs, date selection, session booking, waitlists, booking history and
server-backed receipts. Reservations currently use **cash due at the studio**;
card and wallet payments are unavailable until real provider integration exists.

## Run

Install Flutter stable, then create a local `.env` with `SUPABASE_URL` and
`SUPABASE_ANON_KEY`. Use a publishable/anon client key, never a service-role key.
Apply the checked-in migrations to a matching staging project before using the
new booking RPCs. Firebase configuration is optional for local UI development.

```sh
flutter pub get
flutter run
```

## Design preview

The preview uses labelled sample data and needs no account. Create an empty `.env`
if you do not have one; it is a declared Flutter asset.

```sh
flutter run -t lib/preview.dart
```

See [architecture](docs/ARCHITECTURE.md) for the component map and
[rollout notes](docs/ROLLOUT.md) for verification, migration order and limitations.
