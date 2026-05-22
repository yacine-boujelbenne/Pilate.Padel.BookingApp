# Notification Triggers Guide

## Overview

The notification triggers system (migration `20260521_0012_notification_triggers.sql`) provides comprehensive, automated notification handling for the Pilate Padel booking system. These triggers handle:

1. **Session Creation Notifications** - Notify coach followers when new sessions are created
2. **Session Attachment Notifications** - Notify followers when admin reassigns sessions to new coaches
3. **Waitlist Spot Available Notifications** - Notify waitlist members when spots open up
4. **Waitlist Timestamp Updates** - Track when members are notified about available spots

## Trigger Functions

### 1. `queue_session_created_notification()`

**Event:** `INSERT` on `sessions` table

**Purpose:** When a coach creates a new session, automatically notify all followers of that coach.

**Flow:**
1. Extract coach name from profiles
2. Find all followers of the coach
3. Filter followers by `session_notifications_enabled` preference
4. Build notification title/body with session details
5. Enqueue notification via `enqueue_notification_event()`

**Respects:**
- `notification_preferences.session_notifications_enabled`
- Only notifies followers who explicitly opted in

**Data Included:**
```json
{
  "session_id": "uuid",
  "coach_id": "uuid",
  "coach_name": "string",
  "session_title": "string",
  "session_level": "all|beginner|intermediate|advanced",
  "start_at": "timestamp",
  "end_at": "timestamp",
  "max_participants": "number",
  "price_tnd": "decimal",
  "follower_count": "number"
}
```

**Associated Trigger:** `trg_sessions_queue_created_notification`

---

### 2. `queue_session_attachment_notification()`

**Event:** `UPDATE` on `sessions` table (when `coach_id` changes)

**Purpose:** When an admin reassigns a session to a different coach, notify all followers of the NEW coach.

**Flow:**
1. Check if `coach_id` has changed
2. If changed, extract new coach name
3. Find all followers of the NEW coach
4. Filter followers by `session_notifications_enabled` preference
5. Build notification with context about coach change
6. Enqueue notification

**Respects:**
- `notification_preferences.session_notifications_enabled`
- Only notifies followers who explicitly opted in

**Data Included:**
```json
{
  "session_id": "uuid",
  "new_coach_id": "uuid",
  "previous_coach_id": "uuid",
  "coach_name": "string",
  "session_title": "string",
  "session_level": "string",
  "start_at": "timestamp",
  "end_at": "timestamp",
  "max_participants": "number",
  "price_tnd": "decimal",
  "follower_count": "number"
}
```

**Associated Trigger:** `trg_sessions_queue_attachment_notification`

**Note:** This is a separate trigger from session creation so BOTH notifications can fire if:
- A coach follows another coach, then an admin creates a new session and assigns it to that coach

---

### 3. `queue_waitlist_notification()`

**Event:** `UPDATE` on `bookings` table (when `status` → `cancelled`)

**Purpose:** When a booking is cancelled, check if spots opened up and notify all waitlist members.

**Flow:**
1. Verify booking status changed to `cancelled`
2. Get session details
3. Check if session has available spots (`booked_count < max_participants`)
4. If YES:
   - Get all waitlist members (ordered by position for FIFO)
   - Filter by `waitlist_alerts_enabled` preference
   - Only include those NOT already notified (`notified_at IS NULL`)
5. Notify all eligible members
6. Build notification with available spot count

**Respects:**
- `notification_preferences.waitlist_alerts_enabled`
- Only notifies members who explicitly opted in
- Tracks notification status via `waitlists.notified_at`

**Data Included:**
```json
{
  "session_id": "uuid",
  "session_title": "string",
  "start_at": "timestamp",
  "end_at": "timestamp",
  "coach_id": "uuid",
  "price_tnd": "decimal",
  "booked_count": "number",
  "max_participants": "number",
  "available_spots": "number",
  "waitlist_size": "number"
}
```

**Associated Trigger:** `trg_bookings_queue_cancellation_waitlist`

**Edge Cases Handled:**
- Session already full: No notification sent
- No waitlist members: No notification sent
- Members without notifications enabled: Excluded from recipients
- Already notified members: Excluded (only `notified_at IS NULL`)

---

### 4. `handle_waitlist_notification_sent()`

**Event:** `INSERT` on `notification_events` table (when `event_type = 'waitlist_spot_available'`)

**Purpose:** When a waitlist notification is sent, update the `notified_at` timestamp for all recipients.

**Flow:**
1. Check if event is `event_type = 'waitlist_spot_available'`
2. Extract `session_id` from event data
3. For each recipient in `recipient_user_ids`:
   - Find their waitlist record for this session
   - Update `notified_at = now()` (only if `notified_at IS NULL`)

**Why This Matters:**
- Members who received the notification can proceed to book the spot
- Members not notified (different preference settings) can still join waitlist later
- Prevents duplicate notifications for the same spot opening

**Associated Trigger:** `trg_notification_events_waitlist_update`

---

## Notification Preferences

All triggers respect user notification preferences. Users control:

| Setting | Affects |
|---------|---------|
| `session_notifications_enabled` | Session creation & attachment notifications |
| `waitlist_alerts_enabled` | Waitlist spot available notifications |
| `email_enabled` | Email delivery channel |
| `in_app_enabled` | In-app notification delivery |
| `push_enabled` | Push notification delivery |

**Default:** All enabled for new users (created in `create_notification_preferences()` trigger)

---

## Database Schema Assumptions

### Required Tables

```sql
-- Profiles
profiles (id UUID, first_name TEXT, last_name TEXT)

-- Sessions
sessions (
  id UUID PRIMARY KEY,
  coach_id UUID,
  title TEXT,
  level TEXT,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  max_participants INT,
  booked_count INT,
  price_tnd NUMERIC,
  status TEXT
)

-- Bookings
bookings (
  id UUID PRIMARY KEY,
  member_id UUID,
  session_id UUID,
  status TEXT,
  cancelled_at TIMESTAMPTZ
)

-- Coach Followers
coach_followers (
  id UUID PRIMARY KEY,
  follower_id UUID,
  coach_id UUID,
  UNIQUE (follower_id, coach_id)
)

-- Waitlists
waitlists (
  id UUID PRIMARY KEY,
  member_id UUID,
  session_id UUID,
  position INT,
  notified_at TIMESTAMPTZ,
  UNIQUE (member_id, session_id)
)

-- Notification Preferences
notification_preferences (
  id UUID PRIMARY KEY,
  user_id UUID,
  session_notifications_enabled BOOLEAN DEFAULT true,
  waitlist_alerts_enabled BOOLEAN DEFAULT true,
  email_enabled BOOLEAN DEFAULT true,
  in_app_enabled BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true
)

-- Notification Events
notification_events (
  id UUID PRIMARY KEY,
  event_type TEXT,
  audience_type TEXT,
  recipient_user_ids UUID[],
  title TEXT,
  body TEXT,
  data JSONB,
  source_table TEXT,
  source_record_id UUID,
  status TEXT,
  created_at TIMESTAMPTZ
)
```

---

## Indexes Created

The migration creates performance-optimized indexes:

```sql
-- Efficient waitlist lookups (only non-notified entries)
idx_waitlists_session_id_position (session_id, position) WHERE notified_at IS NULL

-- Efficient coach follower lookups
idx_coach_followers_coach_follower (coach_id, follower_id)

-- Efficient notification preference lookups
idx_notification_preferences_enabled (user_id)
  WHERE session_notifications_enabled = true OR waitlist_alerts_enabled = true

-- Efficient notification event type lookups
idx_notification_events_event_type (event_type) WHERE status = 'pending'
```

---

## Logging & Debugging

All functions use PostgreSQL's `raise log` statements for debugging:

```
queue_session_created_notification: Queued notification for session X to Y followers
queue_session_attachment_notification: Session Z coach changed from A to B
queue_waitlist_notification: Booking X cancelled, checking for waitlist
queue_waitlist_notification: Session Y still full (booked: 10, max: 10)
queue_waitlist_notification: Session Y has available spot(s)
handle_waitlist_notification_sent: Updated waitlist for member X on session Y
```

Check PostgreSQL logs to monitor trigger execution.

---

## Security

All trigger functions use:
- `SECURITY DEFINER`: Functions run with their creator's privileges
- `SET search_path = public`: Explicit schema qualification prevents injection
- Proper permission grants to `anon`, `authenticated`, `service_role`

---

## Performance Considerations

### Trigger Costs

| Trigger | Timing | Cost |
|---------|--------|------|
| `queue_session_created_notification` | AFTER INSERT on sessions | 1 query to fetch coach + followers + preferences |
| `queue_session_attachment_notification` | AFTER UPDATE on sessions | 1 query to fetch new coach + followers + preferences |
| `queue_waitlist_notification` | AFTER UPDATE on bookings | 2 queries (session lookup + waitlist members) |
| `handle_waitlist_notification_sent` | AFTER INSERT on notification_events | 1 UPDATE per recipient (can be batched) |

### Best Practices

1. **Use indexes wisely**: Waitlist queries benefit from the session_id + position index
2. **Monitor trigger logs**: Watch for performance issues during high-volume booking periods
3. **Batch notifications**: The Edge Function processes notification_events in batches
4. **Archive old events**: Consider archiving notification_events after 90 days

---

## Testing Guide

### Test Session Creation Notification

```sql
-- 1. Create a test coach (or use existing)
-- 2. Create a follower
INSERT INTO public.coach_followers (follower_id, coach_id) 
VALUES (current_user_id, coach_id);

-- 3. Ensure notification preferences are enabled
INSERT INTO public.notification_preferences (user_id, session_notifications_enabled)
VALUES (current_user_id, true)
ON CONFLICT (user_id) DO UPDATE SET session_notifications_enabled = true;

-- 4. Create a new session
INSERT INTO public.sessions (coach_id, title, level, start_at, end_at, max_participants, status)
VALUES (coach_id, 'Test Session', 'beginner', now() + interval '2 days', 
        now() + interval '2 days 1 hour', 10, 'scheduled');

-- 5. Check notification_events
SELECT * FROM public.notification_events 
WHERE event_type = 'session_created' 
ORDER BY created_at DESC LIMIT 1;
```

### Test Waitlist Notification

```sql
-- 1. Create a session with limited spots
INSERT INTO public.sessions (coach_id, title, level, start_at, end_at, 
                             max_participants, booked_count, status)
VALUES (coach_id, 'Full Session', 'intermediate', now() + interval '3 days',
        now() + interval '3 days 1 hour', 2, 2, 'scheduled');

-- 2. Add members to waitlist
INSERT INTO public.waitlists (member_id, session_id, position)
VALUES (member_id_1, session_id, 1),
       (member_id_2, session_id, 2);

-- 3. Ensure waitlist preferences enabled
INSERT INTO public.notification_preferences (user_id, waitlist_alerts_enabled)
VALUES (member_id_1, true), (member_id_2, true)
ON CONFLICT (user_id) DO UPDATE SET waitlist_alerts_enabled = true;

-- 4. Cancel a booking
UPDATE public.bookings SET status = 'cancelled' WHERE id = booking_id;

-- 5. Check that notification was created and waitlist updated
SELECT * FROM public.notification_events 
WHERE event_type = 'waitlist_spot_available' 
ORDER BY created_at DESC LIMIT 1;

SELECT member_id, notified_at FROM public.waitlists 
WHERE session_id = session_id 
ORDER BY position;
```

---

## Troubleshooting

### Problem: Notifications not being sent

**Check:**
1. Are notification preferences enabled? `SELECT * FROM notification_preferences WHERE user_id = ?`
2. Are there coach_followers entries? `SELECT * FROM coach_followers WHERE coach_id = ?`
3. Check trigger logs: Look in PostgreSQL logs for `queue_session_created_notification` entries
4. Check notification_events table: `SELECT * FROM notification_events WHERE event_type = 'session_created' ORDER BY created_at DESC`

### Problem: Duplicate notifications

**Cause:** Both `trg_sessions_queue_created_notification` and `trg_sessions_queue_attachment_notification` firing

**Solution:** This is expected behavior if a session is created with a coach who has followers, then the coach is changed. Each trigger fires independently.

### Problem: Waitlist members not notified

**Check:**
1. Is `waitlist_alerts_enabled = true`? `SELECT * FROM notification_preferences WHERE user_id = ? AND waitlist_alerts_enabled = true`
2. Was `notified_at` already set? `SELECT * FROM waitlists WHERE member_id = ? AND session_id = ?`
3. Did the booking cancellation work? `SELECT * FROM bookings WHERE id = ? AND status = 'cancelled'`
4. Did booked_count actually decrease? `SELECT booked_count, max_participants FROM sessions WHERE id = ?`

---

## Future Enhancements

Potential improvements to the trigger system:

1. **Batch Notifications**: Combine multiple session creations into one "digest" notification
2. **Smart Timing**: Schedule notifications for optimal delivery times
3. **Retry Logic**: Automatic retry for failed notification delivery
4. **Analytics**: Track which notification types are most effective
5. **A/B Testing**: Test different notification messages for session creation
6. **Notifications**: Add triggers for session modification (price change, time change, etc.)
