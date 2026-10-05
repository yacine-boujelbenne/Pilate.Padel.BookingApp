# Fléx architecture

The application remains Flutter + Provider + GoRouter + Supabase. This change
introduces a shared motion system, member navigation branches and a booking
repository without replacing the existing coach/admin workflows.

## Client

- `app/`: bootstrap, routing and design tokens. Inter and Noto Serif are bundled
  as Latin subsets renamed FlexSans/FlexSerif, with their SIL Open Font Licenses
  in `assets/fonts/`. Other scripts use the platform font fallback.
- `core/motion/flex_motion.dart`: durations, entrance transitions and breathing
  loops. All decorative motion respects `MediaQuery.disableAnimations`.
- `views/widgets/`: shared buttons, calendar, cards, navigation and state widgets.
- `views/screens/member/member_shell.dart`: four independent branch navigators.
  Switching branches preserves date selection, scroll and screen state.
- `features/bookings/data/booking_repository.dart`: typed data access and RPCs.
- `features/bookings/presentation/reservation_sheet.dart`: review, submission,
  recoverable error and successful result. Pending work blocks duplicate taps,
  back navigation and sheet dismissal.
- `controllers/booking_controller.dart`: member cache and realtime refreshes.
  Mutation progress belongs to the sheet rather than a global page spinner.
- `models/booking.dart`: price snapshot, money collected and joined session.
- `payment_success_screen.dart`: receipt loaded by ID through RLS. Route data
  cannot create a payment-success claim.

Providers below the auth scope are recreated when the user ID changes. Request
sequence numbers prevent older date/profile/booking responses overwriting newer
state. Local day boundaries are converted to UTC before querying timestamps.

## Database

The original eight tables are retained. `bookings.quoted_amount_tnd` stores the
agreed price; `paid_amount_tnd` represents money collected for new reservations.
The migration backfills quotes from current session prices; historical quotes
cannot be reconstructed from the original schema.

Public API functions are SECURITY INVOKER wrappers. Implementations live in
`private`, are SECURITY DEFINER with an empty search path, have explicitly scoped
execute grants, and validate identity/role/ownership before writing.

| Operation | Authority | Transaction |
| --- | --- | --- |
| `reserve_session` | Active member | Lock session, return existing confirmed reservation on retry, check status/time/capacity, snapshot price, create pending cash booking |
| `cancel_reservation` | Owner or active admin | Lock session before booking; cancel once; capacity trigger releases place |
| `join_session_waitlist` | Active member | Lock session; assign FIFO position under the same lock |
| `leave_session_waitlist` | Owner or active admin | Lock session; delete and resequence |
| `record_cash_payment` | Active admin | Record collected amount from immutable quote |
| `approve_session_edit` | Active admin | Apply session changes and approval atomically |

Private role helpers avoid recursive profile policies. Signup always produces a
standard member. Existing server-side coach provisioning subsequently assigns the
coach role using the service role. Triggers protect privileged profile fields,
booking/waitlist mutations and notification content from ordinary member writes.
Coaches propose edits and may cancel their own sessions, but cannot directly
publish or change a session without approval. Cancellation notifications are
inserted in the same transaction as cancellation and make no refund promise.

## Motion contract

- Press: 160 ms, small scale change.
- Selection and state transition: 260 ms.
- Entrance: 420 ms, fade and 14 px translation.
- Confirmation: 800 ms, one checkmark drawing and restrained dots.
- Decorative breathing: 3 seconds each direction; paused by TickerMode and
  disabled when reduced motion is requested.
- Refresh retains content. Initial/date-change loading uses layout placeholders.

## Boundaries and follow-up work

Online payments are explicitly unavailable until a provider, verified callbacks,
refund handling and payment event history are implemented. Existing historical
non-cash 'paid' rows need independent reconciliation; this change does not
invent provider verification for them.

The waitlist stores notification preferences and displays positions. External
push/SMS/email delivery and automatic promotion are not implemented. The existing
`notify-waitlist` call has no checked-in backend implementation. In-app session
cancellation notifications work independently of external delivery.

Padel court scheduling still needs a resource/court model, overlap constraints,
players and durations. The current sessions are coached group classes. This
change does not relabel them as court reservations.

The shared visual components improve staff screens too; staff-specific calendar
layouts, real studio photography and remaining account/profile improvements are
separate extensions of this system.
