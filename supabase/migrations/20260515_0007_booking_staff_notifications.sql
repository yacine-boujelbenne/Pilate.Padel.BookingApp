-- Notify admins and the assigned coach when a booking is created.

create or replace function public.queue_booking_staff_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_title text;
  v_coach_id uuid;
  v_member_name text;
  v_admin_ids uuid[];
  v_recipient_ids uuid[];
begin
  if tg_op <> 'INSERT' or new.status <> 'confirmed' then
    return new;
  end if;

  select s.title, s.coach_id
  into v_session_title, v_coach_id
  from public.sessions s
  where s.id = new.session_id;

  select trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, ''))
  into v_member_name
  from public.profiles p
  where p.id = new.member_id;

  select coalesce(array_agg(distinct p.id), '{}'::uuid[])
  into v_admin_ids
  from public.profiles p
  where p.role = 'admin'
    and coalesce(p.is_blocked, false) = false;

  v_recipient_ids := '{}'::uuid[];
  if v_coach_id is not null then
    v_recipient_ids := array_append(v_recipient_ids, v_coach_id);
  end if;

  if cardinality(v_admin_ids) > 0 then
    v_recipient_ids := coalesce(v_recipient_ids, '{}'::uuid[]) || v_admin_ids;
  end if;

  select coalesce(array_agg(distinct x), '{}'::uuid[])
  into v_recipient_ids
  from unnest(coalesce(v_recipient_ids, '{}'::uuid[])) as x;

  if cardinality(v_recipient_ids) = 0 then
    return new;
  end if;

  perform public.enqueue_notification_event(
    'booking_staff_notified',
    'New booking received',
    coalesce(nullif(v_member_name, ''), 'A member') || ' booked ' || coalesce(v_session_title, 'a session') || '. Please review the booking details.',
    v_recipient_ids,
    'users',
    '{}'::text[],
    'fcm',
    jsonb_build_object(
      'booking_id', new.id,
      'session_id', new.session_id,
      'session_title', v_session_title,
      'coach_id', v_coach_id,
      'member_id', new.member_id,
      'payment_status', new.payment_status,
      'status', new.status
    ),
    'bookings',
    new.id,
    auth.uid()
  );

  return new;
end;
$$;

drop trigger if exists trg_bookings_queue_staff_notifications on public.bookings;
create trigger trg_bookings_queue_staff_notifications
after insert on public.bookings
for each row execute function public.queue_booking_staff_notification();