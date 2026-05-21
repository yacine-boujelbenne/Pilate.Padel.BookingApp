-- Event-driven notification triggers

-- Trigger: When a session is created, notify all coach followers
create or replace function public.queue_session_created_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient_ids uuid[];
  v_coach_name text;
begin
  if tg_op <> 'INSERT' or new.status not in ('scheduled', 'pending') then
    return new;
  end if;

  select coalesce(array_agg(distinct cf.follower_id), '{}'::uuid[])
  into v_recipient_ids
  from public.coach_followers cf
  where cf.coach_id = new.coach_id;

  select p.first_name || ' ' || p.last_name
  into v_coach_name
  from public.profiles p
  where p.id = new.coach_id;

  if cardinality(v_recipient_ids) > 0 then
    perform public.enqueue_notification_event(
      'session_created',
      'New Session: ' || new.title,
      v_coach_name || ' has created a new session: ' || new.title,
      v_recipient_ids,
      'users',
      '{}'::text[],
      'fcm',
      jsonb_build_object(
        'session_id', new.id,
        'coach_id', new.coach_id,
        'session_title', new.title,
        'level', new.level,
        'start_at', new.start_at
      ),
      'sessions',
      new.id,
      auth.uid()
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sessions_queue_created_notification on public.sessions;
create trigger trg_sessions_queue_created_notification
after insert on public.sessions
for each row execute function public.queue_session_created_notification();

-- Trigger: When a booking is cancelled, notify waitlist members
create or replace function public.queue_waitlist_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session record;
  v_recipient_ids uuid[];
  v_available_spots int2;
begin
  if tg_op <> 'UPDATE' or old.status = 'cancelled' and new.status <> 'cancelled' then
    return new;
  end if;

  if new.status <> 'cancelled' and old.status <> 'cancelled' then
    return new;
  end if;

  select s.id, s.title, s.max_participants, s.booked_count, s.coach_id
  into v_session
  from public.sessions s
  where s.id = new.session_id;

  v_available_spots := v_session.max_participants - v_session.booked_count;

  if v_available_spots <= 0 then
    return new;
  end if;

  select coalesce(array_agg(distinct w.member_id), '{}'::uuid[])
  into v_recipient_ids
  from public.waitlists w
  where w.session_id = new.session_id
  order by w.position
  limit v_available_spots;

  if cardinality(v_recipient_ids) > 0 then
    perform public.enqueue_notification_event(
      'waitlist_spot_available',
      'Spot Available: ' || v_session.title,
      'A spot is now available in ' || v_session.title || '. Hurry and book now!',
      v_recipient_ids,
      'users',
      '{}'::text[],
      'fcm',
      jsonb_build_object(
        'session_id', v_session.id,
        'session_title', v_session.title,
        'available_spots', v_available_spots
      ),
      'sessions',
      v_session.id,
      auth.uid()
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_bookings_queue_waitlist_notification on public.bookings;
create trigger trg_bookings_queue_waitlist_notification
after update or delete on public.bookings
for each row execute function public.queue_waitlist_notification();
