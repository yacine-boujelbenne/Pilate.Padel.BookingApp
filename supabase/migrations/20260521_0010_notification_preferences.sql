-- User notification preferences
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

create index if not exists idx_notification_preferences_user_id on public.notification_preferences(user_id);
create index if not exists idx_notification_preferences_enabled on public.notification_preferences(email_enabled, in_app_enabled, push_enabled);

alter table public.notification_preferences enable row level security;

create policy "notification_preferences_select_own_or_admin"
on public.notification_preferences
for select
to authenticated
using (
  user_id = auth.uid() or public.is_admin()
);

create policy "notification_preferences_update_own_or_admin"
on public.notification_preferences
for update
to authenticated
using (
  user_id = auth.uid() or public.is_admin()
)
with check (
  user_id = auth.uid() or public.is_admin()
);

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

drop trigger if exists trg_create_notification_preferences on public.profiles;
create trigger trg_create_notification_preferences
after insert on public.profiles
for each row execute function public.create_notification_preferences();
