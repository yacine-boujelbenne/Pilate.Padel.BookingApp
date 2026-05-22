-- Track coach followers
-- Members can follow coaches to receive notifications about their sessions

create table if not exists public.coach_followers (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.profiles(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  followed_at timestamptz not null default now(),
  constraint coach_followers_unique_relation unique (follower_id, coach_id),
  constraint coach_followers_no_self_follow check (follower_id <> coach_id)
);

-- Indexes for fast lookups
create index if not exists idx_coach_followers_follower_id on public.coach_followers(follower_id);
create index if not exists idx_coach_followers_coach_id on public.coach_followers(coach_id);

-- Enable row level security
alter table public.coach_followers enable row level security;

-- Members can view their own followers or coaches they follow
create policy "coach_followers_select_own"
on public.coach_followers
for select
to authenticated
using (
  follower_id = auth.uid() or
  coach_id = auth.uid()
);

-- Members can follow coaches
create policy "coach_followers_insert_own"
on public.coach_followers
for insert
to authenticated
with check (
  follower_id = auth.uid() and
  exists (
    select 1 from public.profiles p
    where p.id = coach_id and p.role = 'coach'
  )
);

-- Members can unfollow coaches
create policy "coach_followers_delete_own"
on public.coach_followers
for delete
to authenticated
using (follower_id = auth.uid());
