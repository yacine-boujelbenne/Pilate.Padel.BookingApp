-- Add optional session reminder preference.

alter table public.user_settings
add column if not exists reminders_enabled boolean not null default true;