-- Session followers table to track members interested in specific sessions
create table if not exists public.session_followers (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.sessions(id) on delete cascade,
  follow_type text not null default 'direct' check (follow_type in ('coach_derived', 'direct')),
  followed_at timestamptz not null default now(),
  constraint session_followers_unique unique (follower_id, session_id)
);

create index if not exists idx_session_followers_follower_id on public.session_followers(follower_id);
create index if not exists idx_session_followers_session_id on public.session_followers(session_id);
create index if not exists idx_session_followers_follow_type on public.session_followers(follow_type);

alter table public.session_followers enable row level security;

create policy "session_followers_select_own_or_admin"
on public.session_followers
for select
to authenticated
using (
  follower_id = auth.uid() or public.is_admin()
);

create policy "session_followers_insert_own_or_admin"
on public.session_followers
for insert
to authenticated
with check (
  follower_id = auth.uid() or public.is_admin()
);

create policy "session_followers_delete_own_or_admin"
on public.session_followers
for delete
to authenticated
using (
  follower_id = auth.uid() or public.is_admin()
);

create policy "session_followers_service_role_insert"
on public.session_followers
for insert
to service_role
with check (true);

create policy "session_followers_service_role_delete"
on public.session_followers
for delete
to service_role
using (true);
