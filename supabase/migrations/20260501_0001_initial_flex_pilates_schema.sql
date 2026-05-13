-- Fléx Pilates Studio initial schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('member', 'coach', 'admin')),
  first_name text not null,
  last_name text not null,
  phone text,
  speciality text,
  avatar_url text,
  is_blocked boolean not null default false,
  member_tier text not null default 'standard' check (member_tier in ('standard', 'silver', 'gold', 'platinum')),
  created_at timestamptz not null default now()
);

create table if not exists public.studios (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  capacity int2 not null check (capacity > 0)
);

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.profiles(id) on delete cascade,
  studio_id uuid references public.studios(id) on delete set null,
  title text not null,
  level text not null check (level in ('all', 'beginner', 'intermediate', 'advanced')),
  start_at timestamptz not null,
  end_at timestamptz not null,
  max_participants int2 not null check (max_participants > 0),
  booked_count int2 not null default 0 check (booked_count >= 0),
  price_tnd numeric(8,2) not null default 0,
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled', 'completed')),
  created_at timestamptz not null default now(),
  constraint sessions_time_order check (end_at > start_at),
  constraint sessions_capacity_check check (booked_count <= max_participants)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.sessions(id) on delete cascade,
  payment_method text not null check (payment_method in ('cash', 'card', 'mobile')),
  payment_status text not null default 'pending' check (payment_status in ('pending', 'paid', 'rejected')),
  paid_amount_tnd numeric(8,2) not null default 0,
  booked_at timestamptz not null default now(),
  cancelled_at timestamptz,
  status text not null default 'confirmed' check (status in ('confirmed', 'cancelled', 'attended')),
  constraint bookings_unique_member_session unique (member_id, session_id, status)
);

create table if not exists public.waitlists (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.sessions(id) on delete cascade,
  notify_channel text not null check (notify_channel in ('push', 'sms', 'email')),
  position int2 not null default 1,
  notified_at timestamptz,
  created_at timestamptz not null default now(),
  constraint waitlists_unique_member_session unique (member_id, session_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.sessions(id) on delete cascade,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    role,
    first_name,
    last_name,
    phone,
    speciality,
    member_tier
  ) values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'role', 'member'),
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    nullif(new.raw_user_meta_data ->> 'phone', ''),
    nullif(new.raw_user_meta_data ->> 'speciality', ''),
    coalesce(new.raw_user_meta_data ->> 'member_tier', 'standard')
  ) on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'admin'
  );
$$;

create or replace function public.has_role(required_role text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = required_role
  );
$$;

create index if not exists idx_sessions_start_at on public.sessions(start_at);
create index if not exists idx_sessions_coach_id on public.sessions(coach_id);
create index if not exists idx_bookings_member_id on public.bookings(member_id);
create index if not exists idx_bookings_session_id on public.bookings(session_id);
create index if not exists idx_bookings_status on public.bookings(status);
create index if not exists idx_waitlists_session_id on public.waitlists(session_id);
create index if not exists idx_waitlists_member_id on public.waitlists(member_id);
create index if not exists idx_notifications_member_id on public.notifications(member_id);

create or replace function public.recompute_waitlist_positions(target_session_id uuid)
returns void
language plpgsql
as $$
begin
  with ranked as (
    select id, row_number() over (partition by session_id order by created_at, id) as new_position
    from public.waitlists
    where session_id = target_session_id
  )
  update public.waitlists w
  set position = ranked.new_position
  from ranked
  where w.id = ranked.id;
end;
$$;

create or replace function public.sync_session_booked_count()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'confirmed' then
      update public.sessions
      set booked_count = booked_count + 1
      where id = new.session_id;
    end if;
    return new;
  elsif tg_op = 'UPDATE' then
    if old.status = 'confirmed' then
      update public.sessions
      set booked_count = greatest(booked_count - 1, 0)
      where id = old.session_id;
    end if;
    if new.status = 'confirmed' then
      update public.sessions
      set booked_count = booked_count + 1
      where id = new.session_id;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    if old.status = 'confirmed' then
      update public.sessions
      set booked_count = greatest(booked_count - 1, 0)
      where id = old.session_id;
    end if;
    return old;
  end if;
  return null;
end;
$$;

create or replace function public.set_waitlist_position()
returns trigger
language plpgsql
as $$
begin
  select coalesce(max(position), 0) + 1
  into new.position
  from public.waitlists
  where session_id = new.session_id;

  return new;
end;
$$;

create or replace function public.resequence_waitlists_after_change()
returns trigger
language plpgsql
as $$
begin
  perform public.recompute_waitlist_positions(coalesce(new.session_id, old.session_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_bookings_sync_count on public.bookings;
create trigger trg_bookings_sync_count
after insert or update or delete on public.bookings
for each row execute function public.sync_session_booked_count();

drop trigger if exists trg_waitlists_set_position on public.waitlists;
create trigger trg_waitlists_set_position
before insert on public.waitlists
for each row execute function public.set_waitlist_position();

drop trigger if exists trg_waitlists_resequence on public.waitlists;
create trigger trg_waitlists_resequence
after insert or delete on public.waitlists
for each row execute function public.resequence_waitlists_after_change();

alter table public.profiles enable row level security;
alter table public.studios enable row level security;
alter table public.sessions enable row level security;
alter table public.bookings enable row level security;
alter table public.waitlists enable row level security;
alter table public.notifications enable row level security;

-- PROFILES
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy "profiles_select_admin"
on public.profiles
for select
to authenticated
using (public.is_admin());

create policy "profiles_select_coach_trainees"
on public.profiles
for select
to authenticated
using (
  public.has_role('coach')
  and exists (
    select 1
    from public.sessions s
    join public.bookings b on b.session_id = s.id
    where s.coach_id = auth.uid()
      and b.member_id = public.profiles.id
  )
);

create policy "profiles_select_active_coaches"
on public.profiles
for select
to authenticated
using (
  role = 'coach'
  and is_blocked = false
);

create policy "profiles_insert_self"
on public.profiles
for insert
to authenticated
with check (id = auth.uid() or public.is_admin());

create policy "profiles_update_self_or_admin"
on public.profiles
for update
to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

-- STUDIOS
create policy "studios_select_authenticated"
on public.studios
for select
to authenticated
using (true);

create policy "studios_write_admin"
on public.studios
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- SESSIONS
create policy "sessions_select_scheduled_or_staff"
on public.sessions
for select
to authenticated
using (
  status = 'scheduled'
  or coach_id = auth.uid()
  or public.is_admin()
);

create policy "sessions_insert_coach_or_admin"
on public.sessions
for insert
to authenticated
with check (
  coach_id = auth.uid()
  or public.is_admin()
);

create policy "sessions_update_coach_own_or_admin"
on public.sessions
for update
to authenticated
using (
  coach_id = auth.uid()
  or public.is_admin()
)
with check (
  coach_id = auth.uid()
  or public.is_admin()
);

create policy "sessions_delete_admin"
on public.sessions
for delete
to authenticated
using (public.is_admin());

-- BOOKINGS
create policy "bookings_select_own_or_staff"
on public.bookings
for select
to authenticated
using (
  member_id = auth.uid()
  or public.is_admin()
  or exists (
    select 1
    from public.sessions s
    where s.id = public.bookings.session_id
      and s.coach_id = auth.uid()
  )
);

create policy "bookings_insert_own"
on public.bookings
for insert
to authenticated
with check (member_id = auth.uid());

create policy "bookings_update_own_or_admin"
on public.bookings
for update
to authenticated
using (member_id = auth.uid() or public.is_admin())
with check (member_id = auth.uid() or public.is_admin());

create policy "bookings_delete_own_or_admin"
on public.bookings
for delete
to authenticated
using (member_id = auth.uid() or public.is_admin());

-- WAITLISTS
create policy "waitlists_select_own_or_admin"
on public.waitlists
for select
to authenticated
using (member_id = auth.uid() or public.is_admin());

create policy "waitlists_insert_own"
on public.waitlists
for insert
to authenticated
with check (member_id = auth.uid());

create policy "waitlists_update_own_or_admin"
on public.waitlists
for update
to authenticated
using (member_id = auth.uid() or public.is_admin())
with check (member_id = auth.uid() or public.is_admin());

create policy "waitlists_delete_own_or_admin"
on public.waitlists
for delete
to authenticated
using (member_id = auth.uid() or public.is_admin());

-- NOTIFICATIONS
create policy "notifications_select_own_or_admin"
on public.notifications
for select
to authenticated
using (member_id = auth.uid() or public.is_admin());

create policy "notifications_insert_service_or_admin"
on public.notifications
for insert
to authenticated
with check (public.is_admin() or auth.role() = 'service_role');

create policy "notifications_update_own_or_admin"
on public.notifications
for update
to authenticated
using (member_id = auth.uid() or public.is_admin())
with check (member_id = auth.uid() or public.is_admin());
