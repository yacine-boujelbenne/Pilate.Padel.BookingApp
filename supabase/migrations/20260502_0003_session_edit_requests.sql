-- Session edit requests for coach-proposed changes
create table if not exists public.session_edit_requests (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  coach_id uuid not null references public.profiles(id) on delete cascade,
  proposed_title text,
  proposed_start_at timestamptz,
  proposed_end_at timestamptz,
  proposed_max_participants int2 check (proposed_max_participants > 0),
  proposed_price_tnd numeric(8,2),
  proposed_level text check (proposed_level in ('all', 'beginner', 'intermediate', 'advanced')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

alter table public.session_edit_requests enable row level security;

create policy "session_edit_requests_select_own_or_admin"
on public.session_edit_requests
for select
to authenticated
using (coach_id = auth.uid() or public.is_admin());

create policy "session_edit_requests_insert_coach"
on public.session_edit_requests
for insert
to authenticated
with check (
  coach_id = auth.uid()
  and exists (
    select 1
    from public.sessions s
    where s.id = session_id
      and s.coach_id = auth.uid()
  )
);

create policy "session_edit_requests_update_admin"
on public.session_edit_requests
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());
