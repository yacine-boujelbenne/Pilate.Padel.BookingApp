-- Ensure booking inserts can update session booked_count even under RLS.
create or replace function public.sync_session_booked_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'confirmed' then
      update public.sessions
      set booked_count = booked_count + 1
      where id = new.session_id;
    end if;
    return new;
  elsif tg_op = 'UPDATE' then
    if old.status = 'confirmed' then
      update public.sessions
      set booked_count = greatest(booked_count - 1, 0)
      where id = old.session_id;
    end if;
    if new.status = 'confirmed' then
      update public.sessions
      set booked_count = booked_count + 1
      where id = new.session_id;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    if old.status = 'confirmed' then
      update public.sessions
      set booked_count = greatest(booked_count - 1, 0)
      where id = old.session_id;
    end if;
    return old;
  end if;

  return null;
end;
$$;