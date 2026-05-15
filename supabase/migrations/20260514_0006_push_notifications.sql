-- Push notification infrastructure for transactional and broadcast notifications.
-- The Edge Function consumes notification_events rows and writes in-app notifications.

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  installation_id text not null unique,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  push_provider text not null default 'fcm' check (push_provider in ('fcm', 'expo')),
  device_token text not null unique,
  device_name text,
  app_version text,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  last_refreshed_at timestamptz not null default now(),
  deactivated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_devices_user_installation_unique unique (user_id, installation_id)
);

create table if not exists public.notification_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  audience_type text not null default 'users' check (audience_type in ('users', 'all', 'roles')),
  recipient_user_ids uuid[] not null default '{}'::uuid[],
  recipient_roles text[] not null default '{}'::text[],
  push_provider text not null default 'fcm' check (push_provider in ('fcm', 'expo', 'all')),
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  source_table text,
  source_record_id uuid,
  status text not null default 'pending' check (status in ('pending', 'processing', 'sent', 'failed', 'cancelled')),
  scheduled_at timestamptz,
  processed_at timestamptz,
  last_error text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.notification_events(id) on delete cascade,
  device_id uuid not null references public.user_devices(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null check (provider in ('fcm', 'expo')),
  status text not null check (status in ('queued', 'sent', 'failed', 'invalid_token')),
  provider_message_id text,
  error_code text,
  error_message text,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notification_deliveries_unique unique (event_id, device_id)
);

alter table public.notifications
  add column if not exists event_id uuid references public.notification_events(id) on delete set null,
  add column if not exists event_type text,
  add column if not exists channel text not null default 'in_app',
  add column if not exists data jsonb not null default '{}'::jsonb,
  add column if not exists delivered_at timestamptz,
  add column if not exists read_at timestamptz;

alter table public.notifications
  alter column is_read set default false;

create index if not exists idx_user_devices_user_id on public.user_devices(user_id);
create index if not exists idx_user_devices_active on public.user_devices(user_id, is_active);
create index if not exists idx_notification_events_status on public.notification_events(status);
create index if not exists idx_notification_events_created_at on public.notification_events(created_at);
create index if not exists idx_notification_deliveries_event_id on public.notification_deliveries(event_id);
create index if not exists idx_notification_deliveries_device_id on public.notification_deliveries(device_id);
create index if not exists idx_notifications_event_id on public.notifications(event_id);
create index if not exists idx_notifications_created_at on public.notifications(created_at);
create unique index if not exists idx_notifications_event_member_unique
  on public.notifications(event_id, member_id);

create or replace function public.enqueue_notification_event(
  p_event_type text,
  p_title text,
  p_body text,
  p_recipient_user_ids uuid[] default '{}'::uuid[],
  p_audience_type text default 'users',
  p_recipient_roles text[] default '{}'::text[],
  p_push_provider text default 'fcm',
  p_data jsonb default '{}'::jsonb,
  p_source_table text default null,
  p_source_record_id uuid default null,
  p_created_by uuid default null,
  p_scheduled_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_id uuid;
begin
  insert into public.notification_events (
    event_type,
    audience_type,
    recipient_user_ids,
    recipient_roles,
    push_provider,
    title,
    body,
    data,
    source_table,
    source_record_id,
    created_by,
    scheduled_at
  ) values (
    p_event_type,
    p_audience_type,
    coalesce(p_recipient_user_ids, '{}'::uuid[]),
    coalesce(p_recipient_roles, '{}'::text[]),
    coalesce(p_push_provider, 'fcm'),
    p_title,
    p_body,
    coalesce(p_data, '{}'::jsonb),
    p_source_table,
    p_source_record_id,
    p_created_by,
    p_scheduled_at
  ) returning id into v_event_id;

  return v_event_id;
end;
$$;

create or replace function public.queue_session_cancellation_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient_ids uuid[];
  v_paid_bookings record;
begin
  if tg_op <> 'UPDATE' or old.status = new.status or new.status <> 'cancelled' then
    return new;
  end if;

  select coalesce(array_agg(distinct b.member_id), '{}'::uuid[])
  into v_recipient_ids
  from public.bookings b
  where b.session_id = new.id
    and b.status = 'confirmed';

  if cardinality(v_recipient_ids) = 0 then
    return new;
  end if;

  perform public.enqueue_notification_event(
    'session_cancelled',
    'Session cancelled',
    new.title || ' has been cancelled. Your booking will be handled by the studio team.',
    v_recipient_ids,
    'users',
    '{}'::text[],
    'fcm',
    jsonb_build_object(
      'session_id', new.id,
      'session_title', new.title,
      'status', new.status
    ),
    'sessions',
    new.id,
    auth.uid()
  );

  -- For any confirmed bookings that were already paid, create refund records and mark booking cancelled.
  for v_paid_bookings in (
    select id, member_id, paid_amount_tnd
    from public.bookings
    where session_id = new.id
      and status = 'confirmed'
      and payment_status = 'paid'
  ) loop
    insert into public.refunds (booking_id, user_id, amount_tnd, status, created_at)
    values (v_paid_bookings.id, v_paid_bookings.member_id, v_paid_bookings.paid_amount_tnd, 'pending', now());

    update public.bookings
    set status = 'cancelled', cancelled_at = now()
    where id = v_paid_bookings.id;
  end loop;

  return new;
end;
$$;

-- Refunds audit table — actual payment gateway processing should be performed by a secure server-side worker
create table if not exists public.refunds (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings(id) on delete set null,
  user_id uuid references public.profiles(id) on delete set null,
  amount_tnd numeric(8,2) not null default 0,
  currency text not null default 'TND',
  provider text,
  provider_ref text,
  status text not null default 'pending' check (status in ('pending','processing','completed','failed')),
  failure_reason text,
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references public.profiles(id) on delete set null
);

alter table public.refunds enable row level security;

create policy "refunds_admin_only"
on public.refunds
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Payments: when a booking's payment_status transitions to 'paid', notify the member
create or replace function public.queue_booking_payment_completed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op <> 'UPDATE' then
    return new;
  end if;

  if coalesce(old.payment_status,'') <> 'paid' and coalesce(new.payment_status,'') = 'paid' then
    perform public.enqueue_notification_event(
      'payment_received',
      'Payment received',
      'Your payment for the booking is confirmed.',
      array[new.member_id],
      'users',
      '{}'::text[],
      'fcm',
      jsonb_build_object(
        'booking_id', new.id,
        'paid_amount_tnd', new.paid_amount_tnd,
        'payment_status', new.payment_status
      ),
      'bookings',
      new.id,
      auth.uid()
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_bookings_queue_payment_notifications on public.bookings;
create trigger trg_bookings_queue_payment_notifications
after update on public.bookings
for each row execute function public.queue_booking_payment_completed();

-- Chat messages: simple messages table and notification trigger
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid references public.profiles(id) on delete set null,
  chat_room_id uuid,
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.messages enable row level security;

create policy "messages_insert_authenticated"
on public.messages
for insert
to authenticated
with check (sender_id = auth.uid() or public.is_admin());

create policy "messages_select_own_or_admin"
on public.messages
for select
to authenticated
using (sender_id = auth.uid() or recipient_id = auth.uid() or public.is_admin());

create or replace function public.queue_message_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op <> 'INSERT' then
    return new;
  end if;

  if new.recipient_id is not null then
    perform public.enqueue_notification_event(
      'chat_message',
      'New message',
      left(new.content, 200),
      array[new.recipient_id],
      'users',
      '{}'::text[],
      'fcm',
      jsonb_build_object(
        'message_id', new.id,
        'sender_id', new.sender_id,
        'chat_room_id', new.chat_room_id
      ),
      'messages',
      new.id,
      auth.uid()
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_messages_queue_notification on public.messages;
create trigger trg_messages_queue_notification
after insert on public.messages
for each row execute function public.queue_message_notification();

create or replace function public.queue_booking_confirmation_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session_title text;
begin
  if tg_op <> 'INSERT' or new.status <> 'confirmed' then
    return new;
  end if;

  select s.title
  into v_session_title
  from public.sessions s
  where s.id = new.session_id;

  perform public.enqueue_notification_event(
    'booking_confirmed',
    'Booking confirmed',
    coalesce(v_session_title, 'Your session') || ' is confirmed.',
    array[new.member_id],
    'users',
    '{}'::text[],
    'fcm',
    jsonb_build_object(
      'booking_id', new.id,
      'session_id', new.session_id,
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

drop trigger if exists trg_sessions_queue_push_notifications on public.sessions;
create trigger trg_sessions_queue_push_notifications
after update on public.sessions
for each row execute function public.queue_session_cancellation_notifications();

drop trigger if exists trg_bookings_queue_push_notifications on public.bookings;
create trigger trg_bookings_queue_push_notifications
after insert on public.bookings
for each row execute function public.queue_booking_confirmation_notification();

alter table public.user_devices enable row level security;
alter table public.notification_events enable row level security;
alter table public.notification_deliveries enable row level security;

create policy "user_devices_select_own_or_admin"
on public.user_devices
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "user_devices_insert_own_or_admin"
on public.user_devices
for insert
to authenticated
with check (user_id = auth.uid() or public.is_admin());

create policy "user_devices_update_own_or_admin"
on public.user_devices
for update
to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy "user_devices_delete_own_or_admin"
on public.user_devices
for delete
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "notification_events_select_admin_only"
on public.notification_events
for select
to authenticated
using (public.is_admin());

create policy "notification_events_write_admin_only"
on public.notification_events
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "notification_deliveries_select_admin_only"
on public.notification_deliveries
for select
to authenticated
using (public.is_admin());

create policy "notification_deliveries_write_admin_only"
on public.notification_deliveries
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "notifications_select_own_or_admin" on public.notifications;
create policy "notifications_select_own_or_admin"
on public.notifications
for select
to authenticated
using (member_id = auth.uid() or public.is_admin());

drop policy if exists "notifications_insert_service_or_admin" on public.notifications;
create policy "notifications_insert_service_or_admin"
on public.notifications
for insert
to authenticated
with check (public.is_admin() or auth.role() = 'service_role');

drop policy if exists "notifications_update_own_or_admin" on public.notifications;
create policy "notifications_update_own_or_admin"
on public.notifications
for update
to authenticated
using (member_id = auth.uid() or public.is_admin())
with check (member_id = auth.uid() or public.is_admin());