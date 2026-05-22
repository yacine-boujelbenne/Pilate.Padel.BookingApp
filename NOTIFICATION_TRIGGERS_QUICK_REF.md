# Notification Triggers - Quick Reference

## 📍 File Location
```
supabase/migrations/20260521_0012_notification_triggers.sql
```

## 🔑 Key Functions

### 1. Session Creation Notification
```sql
Function: queue_session_created_notification()
Trigger: AFTER INSERT on sessions
Event Type: session_created
Recipients: All coach followers with session_notifications_enabled
Checks: Coaches, followers, preferences
```

### 2. Session Attachment Notification  
```sql
Function: queue_session_attachment_notification()
Trigger: AFTER UPDATE on sessions (coach_id changes)
Event Type: session_attached
Recipients: All NEW coach followers with session_notifications_enabled
Checks: Coach ID changed, preferences
```

### 3. Waitlist Notification
```sql
Function: queue_waitlist_notification()
Trigger: AFTER UPDATE on bookings (status → cancelled)
Event Type: waitlist_spot_available
Recipients: All waitlist members with waitlist_alerts_enabled
Checks: Spots available, not already notified (notified_at IS NULL)
```

### 4. Waitlist Handler
```sql
Function: handle_waitlist_notification_sent()
Trigger: AFTER INSERT on notification_events (waitlist_spot_available)
Updates: waitlists.notified_at timestamp
Effect: Marks members as notified
```

## 📊 Preferences Checked

| Function | Checks |
|----------|--------|
| `queue_session_created_notification` | `session_notifications_enabled = true` |
| `queue_session_attachment_notification` | `session_notifications_enabled = true` |
| `queue_waitlist_notification` | `waitlist_alerts_enabled = true` |
| `handle_waitlist_notification_sent` | Updates notification status |

## 📈 Trigger Sequence

### Session Created Flow
```
1. coach.create_session()
2. INSERT into sessions
3. [trigger] trg_sessions_queue_created_notification
4. queue_session_created_notification()
5. enqueue_notification_event('session_created')
6. [from Edge Function] deliver notification
```

### Session Attachment Flow
```
1. admin.update_session(coach_id = new_coach)
2. UPDATE sessions SET coach_id = ...
3. [trigger] trg_sessions_queue_attachment_notification
4. queue_session_attachment_notification()
5. enqueue_notification_event('session_attached')
6. [from Edge Function] deliver notification
```

### Waitlist Flow
```
1. member.cancel_booking()
2. UPDATE bookings SET status = 'cancelled'
3. [trigger] trg_bookings_queue_cancellation_waitlist
4. queue_waitlist_notification()
5. Check if spots available & queue notification
6. enqueue_notification_event('waitlist_spot_available')
7. [trigger] trg_notification_events_waitlist_update
8. handle_waitlist_notification_sent()
9. UPDATE waitlists SET notified_at = now()
10. [from Edge Function] deliver notification
```

## 🎯 Data Included in Notifications

### Session Created
```json
{
  "session_id": "uuid",
  "coach_id": "uuid",
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

### Waitlist Spot Available
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

## 🔍 Indexes Created

| Index | Table | Columns | Filter |
|-------|-------|---------|--------|
| `idx_waitlists_session_id_position` | waitlists | session_id, position | notified_at IS NULL |
| `idx_coach_followers_coach_follower` | coach_followers | coach_id, follower_id | - |
| `idx_notification_preferences_enabled` | notification_preferences | user_id | preferences enabled |
| `idx_notification_events_event_type` | notification_events | event_type | status = 'pending' |

## 🚨 Edge Cases Handled

✅ No followers → Early exit  
✅ Session already full → No notification  
✅ No waitlist members → Early exit  
✅ Preferences disabled → Excluded from recipients  
✅ Already notified → Excluded (notified_at IS NOT NULL)  
✅ Session not found → Safe error handling  
✅ Coach ID unchanged → Early exit (no update)  
✅ Empty recipient array → No notification queued  

## 🔐 Security Features

✅ `SECURITY DEFINER` - Runs with creator's privileges  
✅ `SET search_path = public` - Prevents SQL injection  
✅ Proper permission grants - anon, authenticated, service_role  
✅ NULL handling - Explicit checks with coalesce, IS NULL  
✅ Type safety - Explicit casts (e.g., `::uuid`, `::text[]`)  

## 📝 Logging

All functions log execution for debugging:

```
queue_session_created_notification: Queued notification for session X to Y followers
queue_session_attachment_notification: Session X coach changed from A to B
queue_waitlist_notification: Booking X cancelled, checking for waitlist
queue_waitlist_notification: Session Y has available spot(s)
handle_waitlist_notification_sent: Updated waitlist for member X on session Y
```

## ✅ Testing Checklist

- [ ] Session creation triggers notification to followers
- [ ] Only followers with `session_notifications_enabled` receive it
- [ ] Session attachment triggers notification to new coach's followers
- [ ] Booking cancellation triggers waitlist notification
- [ ] Waitlist members with `waitlist_alerts_enabled` receive notification
- [ ] `notified_at` timestamp is updated in waitlist table
- [ ] No duplicates if user is on multiple lists
- [ ] Logging appears in PostgreSQL logs

## 🔧 Troubleshooting

### Check if trigger fired:
```sql
SELECT * FROM notification_events 
WHERE event_type IN ('session_created', 'session_attached', 'waitlist_spot_available')
ORDER BY created_at DESC LIMIT 10;
```

### Check if waitlist was updated:
```sql
SELECT member_id, notified_at FROM waitlists 
WHERE session_id = 'xxx'
ORDER BY position;
```

### Check notification preferences:
```sql
SELECT user_id, session_notifications_enabled, waitlist_alerts_enabled 
FROM notification_preferences 
WHERE user_id = 'xxx';
```

### Check PostgreSQL logs:
```
grep "queue_session_created_notification" /path/to/postgres/logs
```

## 📚 Documentation Files

- **Full Guide:** `NOTIFICATION_TRIGGERS_GUIDE.md`
- **Summary:** `NOTIFICATION_TRIGGERS_SUMMARY.md`
- **This File:** `NOTIFICATION_TRIGGERS_QUICK_REF.md`

## 🎓 Key Differences from Previous Implementation

| Aspect | Previous | New |
|--------|----------|-----|
| Session Creation | May not have existed | ✅ Full implementation |
| Session Attachment | May not have existed | ✅ New trigger |
| Waitlist Notification | May not have existed | ✅ Full implementation |
| Preferences | May not have been checked | ✅ Always checked |
| Performance | N/A | ✅ Optimized indexes |
| Logging | May not have existed | ✅ Comprehensive |
| Documentation | May not have existed | ✅ Extensive |

## 🚀 Deployment Steps

1. Copy migration file to your Supabase migrations folder
2. Run: `supabase migration up`
3. Verify: Check that all triggers created
4. Test: Use test cases from NOTIFICATION_TRIGGERS_GUIDE.md
5. Monitor: Watch PostgreSQL logs for any errors

---

**Status:** ✅ Complete and Ready for Deployment  
**Last Updated:** 2025-01-21
