-- Follow subscriptions and notification delivery helpers.

create table if not exists public.coach_follows (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint coach_follows_unique unique (member_id, coach_id)
);

create table if not exists public.session_follows (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.sessions(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint session_follows_unique unique (member_id, session_id)
);

create index if not exists idx_coach_follows_member_id on public.coach_follows(member_id);
create index if not exists idx_coach_follows_coach_id on public.coach_follows(coach_id);
create index if not exists idx_session_follows_member_id on public.session_follows(member_id);
create index if not exists idx_session_follows_session_id on public.session_follows(session_id);

alter table public.coach_follows enable row level security;
alter table public.session_follows enable row level security;

create policy "coach_follows_select_own_or_admin"
on public.coach_follows
for select
to authenticated
using (member_id = auth.uid() or public.is_admin());

create policy "coach_follows_insert_own_or_admin"
on public.coach_follows
for insert
to authenticated
with check (member_id = auth.uid() or public.is_admin());

create policy "coach_follows_update_own_or_admin"
on public.coach_follows
for update
to authenticated
using (member_id = auth.uid() or public.is_admin())
with check (member_id = auth.uid() or public.is_admin());

create policy "coach_follows_delete_own_or_admin"
on public.coach_follows
for delete
to authenticated
using (member_id = auth.uid() or public.is_admin());

create policy "session_follows_select_own_or_admin"
on public.session_follows
for select
to authenticated
using (member_id = auth.uid() or public.is_admin());

create policy "session_follows_insert_own_or_admin"
on public.session_follows
for insert
to authenticated
with check (member_id = auth.uid() or public.is_admin());

create policy "session_follows_update_own_or_admin"
on public.session_follows
for update
to authenticated
using (member_id = auth.uid() or public.is_admin())
with check (member_id = auth.uid() or public.is_admin());

create policy "session_follows_delete_own_or_admin"
on public.session_follows
for delete
to authenticated
using (member_id = auth.uid() or public.is_admin());
