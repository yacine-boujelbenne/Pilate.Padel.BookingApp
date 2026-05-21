-- Coach followers table to track which members follow which coaches
create table if not exists public.coach_followers (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.profiles(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  followed_at timestamptz not null default now(),
  constraint coach_followers_unique unique (follower_id, coach_id),
  constraint coach_followers_self_follow_check check (follower_id != coach_id)
);

create index if not exists idx_coach_followers_follower_id on public.coach_followers(follower_id);
create index if not exists idx_coach_followers_coach_id on public.coach_followers(coach_id);

alter table public.coach_followers enable row level security;

create policy "coach_followers_select_own_or_admin"
on public.coach_followers
for select
to authenticated
using (
  follower_id = auth.uid() or coach_id = auth.uid() or public.is_admin()
);

create policy "coach_followers_insert_own_or_admin"
on public.coach_followers
for insert
to authenticated
with check (
  follower_id = auth.uid() or public.is_admin()
);

create policy "coach_followers_delete_own_or_admin"
on public.coach_followers
for delete
to authenticated
using (
  follower_id = auth.uid() or public.is_admin()
);
