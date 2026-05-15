# Push Notifications

This project is Flutter + Supabase. The implementation in this repo uses:

- `public.user_devices` to store device tokens securely
- `public.notification_events` as the push outbox
- `public.notifications` as the in-app inbox, streamed through Supabase Realtime
- `supabase/functions/send-push-notification` to send FCM or Expo pushes

## Database schema

Apply the migration at `supabase/migrations/20260514_0006_push_notifications.sql`.

It adds:

- `user_devices` for one or more devices per user
- `notification_events` for transactional and broadcast notifications
- `notification_deliveries` for delivery audit and retry tracking
- trigger helpers for session cancellations and booking confirmations
- inbox idempotency on `notifications(event_id, member_id)`

New in this iteration:

- `public.messages` — simple chat message table; inserting a message enqueues a `chat_message` `notification_event` for the recipient.
- `public.refunds` — refund audit table; when a `session` is cancelled the migration enqueues refunds for any paid `bookings` and marks those bookings cancelled. Actual gateway refunds should be processed by a server-side worker using these rows.

## Edge Function

Deploy `supabase/functions/send-push-notification/index.ts` with these env vars:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `WEBHOOK_SECRET`
- `FCM_PROJECT_ID`
- `FCM_SERVICE_ACCOUNT_JSON`

The service account JSON must include the Google service account fields used by FCM HTTP v1.

For Expo, store Expo push tokens in `user_devices.push_provider = 'expo'` and keep `device_token` as the Expo token.

## Database webhook setup

Create a database webhook on `public.notification_events` for `INSERT` events.

Target:

- Edge Function URL: `/functions/v1/send-push-notification`

Headers:

- `x-webhook-secret: <your secret>`

Payload:

- use the default row payload from Supabase

The function accepts both webhook payloads and manual admin calls.

Email notifications and refunds: the current Edge Function focuses on push delivery and in-app notifications. For email delivery (e.g., admin chat messages delivered by email) and for processing refunds, implement a secure server-side worker (Edge Function or separate server) that:

- consumes `notification_events` of type `chat_message` and issues transactional emails via SendGrid/Mailgun
- consumes `refunds` rows (status = `pending`) and calls your payment gateway to issue refunds, then updates `refunds.status` to `completed` or `failed` and records `processed_at`/`processed_by`.

This design keeps payment gateway secrets and refund processing out of the database triggers and lets you manage retries and error handling in a controlled worker.

Quick deployment notes (fast + reasonably secure):

- To send email copies of chat messages, set env vars for your send-push Edge Function:
  - `SENDGRID_API_KEY` — your SendGrid API key
  - `SENDGRID_FROM` — verified sender email

- To run the mock refunds processor now, deploy `supabase/functions/process-refunds` and call it periodically (cron) or on-demand. Replace the mock logic with your payment gateway implementation when time permits.

Example: call the refunds worker manually (once) using `curl`:

```bash
curl -X POST "https://<project>.supabase.co/functions/v1/process-refunds" \
  -H "Authorization: Bearer <SERVICE_ROLE_KEY>"
```

## Flutter token registration

The app-side implementation lives in `lib/services/notification_service.dart`.

It:

- requests notification permission on supported platforms
- upserts the current device token into `user_devices`
- refreshes the token when Firebase rotates it
- subscribes to `notifications` with Supabase Realtime
- shows a local notification in the foreground

Initialize it from `lib/main.dart` after `Supabase.initialize()` and `Firebase.initializeApp()`.

The notification settings toggle in `lib/controllers/settings_controller.dart` now disables the current device when push is turned off.

## Recommended trigger pattern

For transactional notifications, insert a row into `notification_events` from a trigger or security-definer helper.

Examples already included in the migration:

- booking confirmation notifications after `bookings` inserts
- session cancellation notifications after `sessions` status changes to `cancelled`

For marketing or broadcast notifications, insert into `notification_events` with:

- `audience_type = 'all'` for the full audience
- `audience_type = 'roles'` plus `recipient_roles` for role-based campaigns
- `recipient_user_ids` for a targeted list

## Best practices

- Keep the service role key only in Edge Functions and server-side tools.
- Use a separate secret for database webhooks.
- Mark invalid push tokens inactive immediately.
- Keep notification inserts idempotent with the `event_id` and `member_id` unique index.
- Store only opaque device tokens in `user_devices`; do not store auth tokens there.
- Respect `user_settings.push_enabled` before sending push, but still create in-app notifications.

## Folder structure

Recommended notification-related structure:

```text
lib/
  services/
    notification_service.dart
    supabase_service.dart
supabase/
  migrations/
    20260514_0006_push_notifications.sql
  functions/
    send-push-notification/
      index.ts
docs/
  push_notifications.md
```