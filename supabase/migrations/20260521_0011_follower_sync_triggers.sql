-- Synchronization triggers to keep coach_followers and session_followers in sync

-- When a member follows a coach, add them to session_followers for all active sessions
create or replace function public.sync_coach_follow_to_sessions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.session_followers (follower_id, session_id, follow_type)
    select new.follower_id, s.id, 'coach_derived'
    from public.sessions s
    where s.coach_id = new.coach_id
      and s.status in ('scheduled', 'pending')
    on conflict (follower_id, session_id) do nothing;
  elsif tg_op = 'DELETE' then
    delete from public.session_followers
    where follower_id = old.follower_id
      and follow_type = 'coach_derived'
      and session_id in (
        select id from public.sessions where coach_id = old.coach_id
      );
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_coach_follow_to_sessions on public.coach_followers;
create trigger trg_sync_coach_follow_to_sessions
after insert or delete on public.coach_followers
for each row execute function public.sync_coach_follow_to_sessions();

-- When a new session is created, add all coach followers to session_followers
create or replace function public.sync_new_session_to_followers()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' and new.status in ('scheduled', 'pending') then
    insert into public.session_followers (follower_id, session_id, follow_type)
    select cf.follower_id, new.id, 'coach_derived'
    from public.coach_followers cf
    where cf.coach_id = new.coach_id
    on conflict (follower_id, session_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sync_new_session_to_followers on public.sessions;
create trigger trg_sync_new_session_to_followers
after insert on public.sessions
for each row execute function public.sync_new_session_to_followers();
