-- Track session followers
-- Members can follow specific sessions either directly or indirectly through coach following

create table if not exists public.session_followers (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null references public.sessions(id) on delete cascade,
  follow_type text not null check (follow_type in ('coach_derived', 'direct')),
  followed_at timestamptz not null default now(),
  constraint session_followers_unique_relation unique (follower_id, session_id)
);

-- Indexes for fast lookups
create index if not exists idx_session_followers_follower_id on public.session_followers(follower_id);
create index if not exists idx_session_followers_session_id on public.session_followers(session_id);
create index if not exists idx_session_followers_follow_type on public.session_followers(follow_type);

-- Enable row level security
alter table public.session_followers enable row level security;

-- Members can view their own session follows and coaches can view their session's followers
create policy "session_followers_select_own"
on public.session_followers
for select
to authenticated
using (
  follower_id = auth.uid() or
  exists (
    select 1 from public.sessions s
    where s.id = session_id and s.coach_id = auth.uid()
  )
);

-- Members can follow sessions directly
create policy "session_followers_insert_direct"
on public.session_followers
for insert
to authenticated
with check (
  follower_id = auth.uid() and
  follow_type = 'direct'
);

-- System (via trigger) can insert coach_derived follows
-- This policy is used by the trigger function to create derived follows
create policy "session_followers_insert_system"
on public.session_followers
for insert
to service_role
with check (true);

-- Members can delete their own follows
create policy "session_followers_delete_own"
on public.session_followers
for delete
to authenticated
using (follower_id = auth.uid());

-- System can delete coach_derived follows
create policy "session_followers_delete_system"
on public.session_followers
for delete
to service_role
using (follow_type = 'coach_derived');
