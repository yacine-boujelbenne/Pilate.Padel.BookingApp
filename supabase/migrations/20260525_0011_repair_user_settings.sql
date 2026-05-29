-- Repair user settings table in environments where earlier migrations were not applied.
-- Safe to run multiple times.

create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  push_enabled boolean not null default true,
  email_enabled boolean not null default true,
  sms_enabled boolean not null default false,
  language text,
  reminders_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.user_settings
  add column if not exists push_enabled boolean not null default true,
  add column if not exists email_enabled boolean not null default true,
  add column if not exists sms_enabled boolean not null default false,
  add column if not exists language text,
  add column if not exists reminders_enabled boolean not null default true,
  add column if not exists updated_at timestamptz not null default now();

alter table public.user_settings enable row level security;

drop policy if exists "user_settings_select_own" on public.user_settings;
drop policy if exists "user_settings_insert_own" on public.user_settings;
drop policy if exists "user_settings_update_own" on public.user_settings;

create policy "user_settings_select_own"
on public.user_settings
for select
to authenticated
using (user_id = auth.uid());

create policy "user_settings_insert_own"
on public.user_settings
for insert
to authenticated
with check (user_id = auth.uid());

create policy "user_settings_update_own"
on public.user_settings
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
