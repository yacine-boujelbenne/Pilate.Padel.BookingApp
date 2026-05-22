-- Comprehensive notification trigger functions for the notification system
-- Handles session creation/attachment and waitlist notifications with preference checking

-- ============================================================================
-- 1. SESSION CREATION NOTIFICATION TRIGGER
-- ============================================================================
-- When a coach creates a new session, notify all coach followers

create or replace function public.queue_session_created_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_follower_record record;
  v_follower_ids uuid[];
  v_recipient_ids uuid[];
  v_coach_name text;
  v_session_level text;
  v_start_time text;
  v_title text;
  v_body text;
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  -- Get the coach's name
  select first_name || ' ' || last_name
  into v_coach_name
  from public.profiles
  where id = new.coach_id;

  -- Get all followers of this coach
  select coalesce(array_agg(distinct follower_id), '{}'::uuid[])
  into v_follower_ids
  from public.coach_followers
  where coach_id = new.coach_id;

  -- Filter followers based on notification preferences
  -- Only notify members who have session_notifications_enabled
  select coalesce(array_agg(distinct follower_id), '{}'::uuid[])
  into v_recipient_ids
  from (
    select cf.follower_id
    from public.coach_followers cf
    where cf.coach_id = new.coach_id
      and exists (
        select 1
        from public.notification_preferences np
        where np.user_id = cf.follower_id
          and np.session_notifications_enabled = true
      )
  ) filtered_followers;

  -- If no followers or no one has opted in, exit early
  if cardinality(v_recipient_ids) = 0 then
    raise log 'queue_session_created_notification: No followers to notify for session %', new.id;
    return new;
  end if;

  -- Format session level for display
  v_session_level := case new.level
    when 'all' then 'All levels'
    when 'beginner' then 'Beginner'
    when 'intermediate' then 'Intermediate'
    when 'advanced' then 'Advanced'
    else new.level
  end;

  -- Format start time for display
  v_start_time := to_char(new.start_at, 'Mon DD, HH24:MI');

  -- Build notification title and body
  v_title := 'New session from ' || coalesce(v_coach_name, 'your coach');
  v_body := new.title || ' (' || v_session_level || ') - ' || v_start_time;

  -- Enqueue the notification event
  perform public.enqueue_notification_event(
    p_event_type := 'session_created',
    p_title := v_title,
    p_body := v_body,
    p_recipient_user_ids := v_recipient_ids,
    p_audience_type := 'users',
    p_push_provider := 'fcm',
    p_data := jsonb_build_object(
      'session_id', new.id,
      'coach_id', new.coach_id,
      'coach_name', v_coach_name,
      'session_title', new.title,
      'session_level', new.level,
      'start_at', new.start_at,
      'end_at', new.end_at,
      'max_participants', new.max_participants,
      'price_tnd', new.price_tnd,
      'follower_count', cardinality(v_recipient_ids)
    ),
    p_source_table := 'sessions',
    p_source_record_id := new.id,
    p_created_by := new.coach_id
  );

  raise log 'queue_session_created_notification: Queued notification for session % to % followers',
    new.id, cardinality(v_recipient_ids);

  return new;
end;
$$;

-- Drop existing trigger if it exists
drop trigger if exists trg_sessions_queue_created_notification on public.sessions;

-- Create trigger for new sessions
create trigger trg_sessions_queue_created_notification
after insert on public.sessions
for each row execute function public.queue_session_created_notification();


-- ============================================================================
-- 2. SESSION ATTACHMENT NOTIFICATION TRIGGER
-- ============================================================================
-- When admin attaches a session to a new coach (coach_id changes),
-- notify all followers of the NEW coach

create or replace function public.queue_session_attachment_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient_ids uuid[];
  v_new_coach_name text;
  v_session_level text;
  v_start_time text;
  v_title text;
  v_body text;
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  -- Only process if coach_id has changed
  if old.coach_id = new.coach_id then
    return new;
  end if;

  raise log 'queue_session_attachment_notification: Session % coach changed from % to %',
    new.id, old.coach_id, new.coach_id;

  -- Get the NEW coach's name
  select first_name || ' ' || last_name
  into v_new_coach_name
  from public.profiles
  where id = new.coach_id;

  -- Get all followers of the NEW coach who have opted in for notifications
  select coalesce(array_agg(distinct cf.follower_id), '{}'::uuid[])
  into v_recipient_ids
  from public.coach_followers cf
  where cf.coach_id = new.coach_id
    and exists (
      select 1
      from public.notification_preferences np
      where np.user_id = cf.follower_id
        and np.session_notifications_enabled = true
    );

  -- If no followers or no one has opted in, exit early
  if cardinality(v_recipient_ids) = 0 then
    raise log 'queue_session_attachment_notification: No followers to notify for session %', new.id;
    return new;
  end if;

  -- Format session level for display
  v_session_level := case new.level
    when 'all' then 'All levels'
    when 'beginner' then 'Beginner'
    when 'intermediate' then 'Intermediate'
    when 'advanced' then 'Advanced'
    else new.level
  end;

  -- Format start time for display
  v_start_time := to_char(new.start_at, 'Mon DD, HH24:MI');

  -- Build notification title and body
  v_title := 'New session from ' || coalesce(v_new_coach_name, 'your coach');
  v_body := new.title || ' (' || v_session_level || ') - ' || v_start_time;

  -- Enqueue the notification event
  perform public.enqueue_notification_event(
    p_event_type := 'session_attached',
    p_title := v_title,
    p_body := v_body,
    p_recipient_user_ids := v_recipient_ids,
    p_audience_type := 'users',
    p_push_provider := 'fcm',
    p_data := jsonb_build_object(
      'session_id', new.id,
      'new_coach_id', new.coach_id,
      'previous_coach_id', old.coach_id,
      'coach_name', v_new_coach_name,
      'session_title', new.title,
      'session_level', new.level,
      'start_at', new.start_at,
      'end_at', new.end_at,
      'max_participants', new.max_participants,
      'price_tnd', new.price_tnd,
      'follower_count', cardinality(v_recipient_ids)
    ),
    p_source_table := 'sessions',
    p_source_record_id := new.id,
    p_created_by := auth.uid()
  );

  raise log 'queue_session_attachment_notification: Queued notification for session % to % followers of new coach',
    new.id, cardinality(v_recipient_ids);

  return new;
end;
$$;

-- Drop existing trigger if it exists
drop trigger if exists trg_sessions_queue_attachment_notification on public.sessions;

-- Create trigger for session coach changes
-- Note: This is a separate trigger from the creation trigger so both can fire
create trigger trg_sessions_queue_attachment_notification
after update on public.sessions
for each row execute function public.queue_session_attachment_notification();


-- ============================================================================
-- 3. BOOKING CANCELLATION & WAITLIST NOTIFICATION TRIGGER
-- ============================================================================
-- When a booking is cancelled, check if a spot opened up and notify waitlist members

create or replace function public.queue_waitlist_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_record record;
  v_waitlist_record record;
  v_recipient_ids uuid[];
  v_session_title text;
  v_start_time text;
  v_notification_title text;
  v_notification_body text;
begin
  -- Only process if status changed to cancelled
  if tg_op <> 'UPDATE' or old.status = new.status or new.status <> 'cancelled' then
    return new;
  end if;

  raise log 'queue_waitlist_notification: Booking % cancelled, checking for waitlist', new.id;

  -- Get the session details
  select s.*
  into v_session_record
  from public.sessions s
  where s.id = new.session_id;

  if v_session_record is null then
    raise log 'queue_waitlist_notification: Session % not found', new.session_id;
    return new;
  end if;

  -- Check if the session now has available spots
  -- (booked_count < max_participants)
  if v_session_record.booked_count >= v_session_record.max_participants then
    raise log 'queue_waitlist_notification: Session % still full (booked: %, max: %)',
      new.session_id, v_session_record.booked_count, v_session_record.max_participants;
    return new;
  end if;

  raise log 'queue_waitlist_notification: Session % has available spot(s)', new.session_id;

  -- Get all waitlist members for this session, ordered by position (FIFO)
  -- Only include those who have session_notifications_enabled
  select coalesce(array_agg(distinct w.member_id), '{}'::uuid[])
  into v_recipient_ids
  from public.waitlists w
  where w.session_id = new.session_id
    and w.notified_at is null  -- Not already notified about this spot
    and exists (
      select 1
      from public.notification_preferences np
      where np.user_id = w.member_id
        and np.waitlist_alerts_enabled = true
    )
  order by w.position asc;

  -- If no waitlist members or no one has opted in, exit early
  if cardinality(v_recipient_ids) = 0 then
    raise log 'queue_waitlist_notification: No eligible waitlist members for session %', new.session_id;
    return new;
  end if;

  -- Format start time for display
  v_start_time := to_char(v_session_record.start_at, 'Mon DD, HH24:MI');

  -- Build notification details
  v_notification_title := 'Spot available!';
  v_notification_body := v_session_record.title || ' - ' || v_start_time || ' now has an available spot.';

  -- Enqueue the notification event
  perform public.enqueue_notification_event(
    p_event_type := 'waitlist_spot_available',
    p_title := v_notification_title,
    p_body := v_notification_body,
    p_recipient_user_ids := v_recipient_ids,
    p_audience_type := 'users',
    p_push_provider := 'fcm',
    p_data := jsonb_build_object(
      'session_id', new.session_id,
      'session_title', v_session_record.title,
      'start_at', v_session_record.start_at,
      'end_at', v_session_record.end_at,
      'coach_id', v_session_record.coach_id,
      'price_tnd', v_session_record.price_tnd,
      'booked_count', v_session_record.booked_count,
      'max_participants', v_session_record.max_participants,
      'available_spots', v_session_record.max_participants - v_session_record.booked_count,
      'waitlist_size', cardinality(v_recipient_ids)
    ),
    p_source_table := 'bookings',
    p_source_record_id := new.id
  );

  raise log 'queue_waitlist_notification: Queued notification for session % to % waitlist members',
    new.session_id, cardinality(v_recipient_ids);

  return new;
end;
$$;

-- Drop existing trigger if it exists
drop trigger if exists trg_bookings_queue_cancellation_waitlist on public.bookings;

-- Create trigger for booking cancellation
create trigger trg_bookings_queue_cancellation_waitlist
after update on public.bookings
for each row execute function public.queue_waitlist_notification();


-- ============================================================================
-- 4. WAITLIST NOTIFICATION TIMESTAMP UPDATE TRIGGER
-- ============================================================================
-- When a notification is sent for a waitlist spot, update the notified_at timestamp
-- This allows members who received the notification to proceed with booking

create or replace function public.handle_waitlist_notification_sent()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_waitlist_record record;
  v_member_id uuid;
  v_session_id uuid;
begin
  if tg_op <> 'INSERT' or new.event_type <> 'waitlist_spot_available' then
    return new;
  end if;

  raise log 'handle_waitlist_notification_sent: Event % for session %',
    new.id, (new.data ->> 'session_id')::uuid;

  -- Extract session_id from the event data
  v_session_id := (new.data ->> 'session_id')::uuid;

  if v_session_id is null then
    raise log 'handle_waitlist_notification_sent: No session_id in event data';
    return new;
  end if;

  -- For each recipient of this notification, update their waitlist notified_at timestamp
  -- This signals that they've been notified and can proceed to book
  for v_member_id in
    select unnest(new.recipient_user_ids)
  loop
    update public.waitlists
    set notified_at = now()
    where member_id = v_member_id
      and session_id = v_session_id
      and notified_at is null;

    raise log 'handle_waitlist_notification_sent: Updated waitlist for member % on session %',
      v_member_id, v_session_id;
  end loop;

  return new;
end;
$$;

-- Drop existing trigger if it exists
drop trigger if exists trg_notification_events_waitlist_update on public.notification_events;

-- Create trigger for notification event creation
create trigger trg_notification_events_waitlist_update
after insert on public.notification_events
for each row execute function public.handle_waitlist_notification_sent();


-- ============================================================================
-- 5. INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Index for efficient waitlist lookups by session
create index if not exists idx_waitlists_session_id_position on public.waitlists(session_id, position)
where notified_at is null;

-- Index for efficient coach_followers lookups
create index if not exists idx_coach_followers_coach_follower on public.coach_followers(coach_id, follower_id);

-- Index for efficient notification_preferences lookups
create index if not exists idx_notification_preferences_enabled on public.notification_preferences(user_id)
where session_notifications_enabled = true or waitlist_alerts_enabled = true;

-- Index for notification_events lookups by event_type
create index if not exists idx_notification_events_event_type on public.notification_events(event_type)
where status = 'pending';


-- ============================================================================
-- 6. COMMENTS FOR DOCUMENTATION
-- ============================================================================

comment on function public.queue_session_created_notification() is
'Trigger function that fires when a new session is created.
Notifies all followers of the coach who have opted in for session notifications.
Respects notification preferences from the notification_preferences table.';

comment on function public.queue_session_attachment_notification() is
'Trigger function that fires when a session is attached to a new coach (coach_id changes).
Similar to session creation, notifies all followers of the NEW coach.
Used when admin reassigns a session to a different coach.';

comment on function public.queue_waitlist_notification() is
'Trigger function that fires when a booking is cancelled.
Checks if the cancelled booking opened up a spot (booked_count < max_participants).
If yes, notifies ALL waitlist members who have opted in for waitlist alerts.
Marks waitlist members as notified so they know they can proceed to book.';

comment on function public.handle_waitlist_notification_sent() is
'Trigger function that fires when a notification event is created for waitlist_spot_available.
Updates the notified_at timestamp for all recipients in the waitlist table.
This allows members to distinguish between pending and already-notified spots.';


-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

-- Ensure the functions have proper permissions for execution
grant execute on function public.queue_session_created_notification() to anon, authenticated, service_role;
grant execute on function public.queue_session_attachment_notification() to anon, authenticated, service_role;
grant execute on function public.queue_waitlist_notification() to anon, authenticated, service_role;
grant execute on function public.handle_waitlist_notification_sent() to anon, authenticated, service_role;
