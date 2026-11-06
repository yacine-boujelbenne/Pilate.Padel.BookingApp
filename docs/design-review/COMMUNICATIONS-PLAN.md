# Communications plan — free and open-source first

Updated 5 November 2026. Planning document only; no services installed, integrations activated, messages sent, subscriptions purchased, database contracts changed, or application code modified.

## Current decisions

Preserve the Flutter/Provider/GoRouter/Supabase architecture and existing authentication. Retain the original mint/sage palette. Leave payment improvements until the final work package. Future messaging, notifications and confirmations should use free, open-source components and remain adaptable to later requirements.

“Free software” means no software-license fee. Hosted free tiers have usage limits; self-hosting needs infrastructure and maintenance. Avoid paid-only dependencies and do not promise unlimited free delivery.

## Proposed building blocks

| Capability | Preferred approach | What it does and does not provide |
|---|---|---|
| Reservation confirmation | Flutter confirmation UI after the existing booking write succeeds | No external messaging API needed for an in-app acknowledgment. A failed follow-up refresh must not tell the member their successful reservation failed or trigger a duplicate insert. A success screen does not prove an email/push was delivered |
| Persistent in-app notifications | Existing Supabase `notifications` table + authenticated reads, existing read-state contract, and Realtime updates where configured | Preserve the stored record as the authority; refetch on reconnect/resume. Verify current RLS/publication/server-write behavior; the audit found gaps. No promise that the app is already wired to deliver notifications |
| Future member/club messaging | Persist messages in Supabase Postgres; use Supabase Realtime for updates | Reuses the existing backend and auth. Requires separately specified conversations, participants, staff access, retention and message schema/RLS. Realtime Broadcast alone is not persistent chat history or guaranteed delivery |
| Local reminders | Existing `flutter_local_notifications` package, verified against its locked version and target OS | Open-source native notification display/scheduling; no messaging-service license fee. Local reminders cannot receive a cancellation or queue opening from a server while offline. Web needs a separate supported path |
| Remote push candidate | Evaluate self-hosted **ntfy** only when platform/delivery requirements are defined | Open-source HTTP notification tooling; not a drop-in invisible replacement for app-native push. Authentication/private topics, integration model, background behavior and platform support need validation. Do not require members to install a second app without a product decision |
| Confirmation emails | Preserve Supabase Auth confirmation/reset flows; future booking emails use a server-side SMTP adapter | Auth mail is separate from transactional booking mail. An open-source self-hosted server such as **Postal** is a candidate, not a deployment commitment. Domain, DNS, hosting, reputation and delivery management remain operational requirements |

Supabase Realtime is [Apache-2.0 licensed](https://github.com/supabase/realtime). Its [documentation](https://supabase.com/docs/guides/realtime) covers Broadcast, Presence and Postgres Changes. Its server documentation explicitly says delivery of every realtime message is not guaranteed. Store messages/notifications durably and recover via authenticated fetches. Supabase Cloud's [free plan](https://supabase.com/pricing) has quotas; self-hosted components do not remove hosting costs.

The existing [Flutter Local Notifications project](https://github.com/MaikuB/flutter_local_notifications) provides local notification functionality. Retain the currently locked version initially; do not upgrade merely because the provider integration is being planned.

[ntfy](https://github.com/binwiederhier/ntfy) is open-source and exposes an [HTTP publishing API](https://docs.ntfy.sh/). Its [configuration guide](https://docs.ntfy.sh/config/) covers users, access control and private instances. The stock iOS client requires upstream APNs/Firebase-connected infrastructure for immediate delivery; a custom app requires its own supported platform integration. Using self-hosted ntfy does not eliminate those platform dependencies or make background delivery available automatically.

[Postal](https://github.com/postalserver/postal) is an MIT-licensed self-hosted mail delivery platform. It is an option for later assessment, not a claim that reliable email can be run without infrastructure costs. Supabase's [SMTP guidance](https://supabase.com/docs/guides/auth/auth-smtp) describes the restricted default auth-mail service and custom SMTP setup. Do not use the default auth-mail service as a general booking-email API.

## Existing Firebase integration

Keep the installed Firebase integration intact while redesigning existing UI. Google describes [FCM as having no usage charge](https://firebase.google.com/products/cloud-messaging); it is still a hosted Google service, not an open-source notification server. Preserving it is different from selecting it to meet the user's free/open-source requirement. Do not silently replace it or add another push SDK now. Revisit transport once Android/iOS/web requirements and the open-source boundary are agreed.

## Delivery behavior to design for

- A confirmed reservation, notification record creation, provider acceptance and confirmed device delivery are different states. Display only states the actual integration supports.
- A reservation is confirmed by the successful existing booking operation; messaging failures must not cancel it or cause duplicate booking retries.
- Notification permissions and per-user preferences are respected. A disabled channel must not be presented as enabled or delivered.
- Only authorized recipients may read a notification or conversation. Do not publish member information to public ntfy topics or unauthenticated broadcast channels.
- Publishing credentials remain server-side. Messages use stable event IDs and idempotent dispatch when the delivery backend is implemented; retries must not duplicate user notifications.
- Reconnect/resume fetches recover missed updates. Background push and reliable retries need a defined server-side delivery path; realtime sockets alone are insufficient.
- SMS/WhatsApp are not assumed to offer unrestricted free production delivery. Do not add a paid service, use unofficial automation, or promise those channels now. Preserve existing UI/data contracts until their later integration scope is resolved.

## Incremental scope

1. Improve the visual reservation confirmation and existing notification states using the current contracts, preserving the payment handoff.
2. Validate existing notification persistence/permissions and expose only working actions. Record backend gaps for a dedicated change rather than silently altering RLS in a UI patch.
3. Define the future messaging participants and target platforms before choosing a chat schema or remote push setup.
4. Add a small server-side delivery abstraction when those integrations are implemented, with existing Supabase as the durable source. Avoid adding unused provider classes or SDKs now.
5. Address payment design and provider integration last, after the user supplies the later requirements.

No external messages are authorized by this planning work. Integration verification should use test recipients and an appropriate development environment when implementation is requested.
