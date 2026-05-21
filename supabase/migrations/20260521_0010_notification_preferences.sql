-- User notification preferences
-- Track which notification channels and types are enabled for each user

create table if not exists public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  email_enabled boolean not null default true,
  in_app_enabled boolean not null default true,
  push_enabled boolean not null default true,
  session_notifications_enabled boolean not null default true,
  coach_updates_enabled boolean not null default true,
  waitlist_alerts_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index on user_id for fast lookups
create index if not exists idx_notification_preferences_user_id on public.notification_preferences(user_id);

-- Enable row level security
alter table public.notification_preferences enable row level security;

-- Users can view their own preferences
create policy "notification_preferences_select_own"
on public.notification_preferences
for select
to authenticated
using (user_id = auth.uid());

-- Users can update their own preferences
create policy "notification_preferences_update_own"
on public.notification_preferences
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Create a function to automatically create notification_preferences when a new user signs up
create or replace function public.create_notification_preferences()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  
  return new;
end;
$$;

-- Trigger to create preferences when a profile is created
drop trigger if exists trg_profiles_create_notification_preferences on public.profiles;
create trigger trg_profiles_create_notification_preferences
after insert on public.profiles
for each row execute function public.create_notification_preferences();

-- Update the updated_at timestamp when preferences are modified
create or replace function public.update_notification_preferences_timestamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_notification_preferences_update_timestamp on public.notification_preferences;
create trigger trg_notification_preferences_update_timestamp
before update on public.notification_preferences
for each row execute function public.update_notification_preferences_timestamp();
