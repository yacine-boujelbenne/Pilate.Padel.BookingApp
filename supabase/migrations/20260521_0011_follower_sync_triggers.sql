-- Synchronization triggers for coach followers and session followers
-- Automatically maintains consistency between coach follows and session follows

-- Function to add a member to session_followers when they follow a coach
create or replace function public.sync_coach_follow_to_sessions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session record;
begin
  if tg_op = 'INSERT' then
    -- When a member follows a coach, add them to all active/upcoming sessions by that coach
    for v_session in
      select id
      from public.sessions
      where coach_id = new.coach_id
        and status in ('scheduled', 'pending')
        and start_at > now()
    loop
      insert into public.session_followers (follower_id, session_id, follow_type)
      values (new.follower_id, v_session.id, 'coach_derived')
      on conflict (follower_id, session_id) do nothing;
    end loop;
  end if;
  
  return new;
end;
$$;

-- Trigger when a coach follow is created
drop trigger if exists trg_coach_followers_sync_sessions on public.coach_followers;
create trigger trg_coach_followers_sync_sessions
after insert on public.coach_followers
for each row execute function public.sync_coach_follow_to_sessions();

-- Function to add coach's followers to a new session
create or replace function public.sync_session_to_coach_followers()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_follower record;
begin
  if tg_op = 'INSERT' then
    -- When a new session is created, add all of the coach's followers to session_followers
    for v_follower in
      select follower_id
      from public.coach_followers
      where coach_id = new.coach_id
    loop
      insert into public.session_followers (follower_id, session_id, follow_type)
      values (v_follower.follower_id, new.id, 'coach_derived')
      on conflict (follower_id, session_id) do nothing;
    end loop;
  end if;
  
  return new;
end;
$$;

-- Trigger when a new session is created
drop trigger if exists trg_sessions_sync_coach_followers on public.sessions;
create trigger trg_sessions_sync_coach_followers
after insert on public.sessions
for each row execute function public.sync_session_to_coach_followers();

-- Function to clean up session_followers when a coach follow is removed
create or replace function public.cleanup_coach_unfollow_sessions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    -- When a member unfollows a coach, remove them from all session_followers entries
    -- that are marked as coach_derived for that coach's sessions
    delete from public.session_followers
    where follower_id = old.follower_id
      and follow_type = 'coach_derived'
      and session_id in (
        select id from public.sessions where coach_id = old.coach_id
      );
  end if;
  
  return old;
end;
$$;

-- Trigger when a coach follow is deleted
drop trigger if exists trg_coach_followers_cleanup_sessions on public.coach_followers;
create trigger trg_coach_followers_cleanup_sessions
after delete on public.coach_followers
for each row execute function public.cleanup_coach_unfollow_sessions();
