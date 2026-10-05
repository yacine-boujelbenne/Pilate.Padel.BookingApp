-- Reviewed as a unit with the new Flutter RPC callers. Apply to staging first.
begin;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

-- Role lookups must not recurse through profiles' own RLS policies.
-- These helpers expose only the caller's role, never another user's data.
create or replace function private.has_role(required_role text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles
    where id = (select auth.uid()) and role = required_role and not is_blocked);
$$;
revoke all on function private.has_role(text) from public, anon;
grant execute on function private.has_role(text) to authenticated;

create or replace function public.is_admin()
returns boolean language sql stable security invoker set search_path = '' as $$
  select private.has_role('admin');
$$;
create or replace function public.has_role(required_role text)
returns boolean language sql stable security invoker set search_path = '' as $$
  select private.has_role(required_role);
$$;
revoke all on function public.is_admin(), public.has_role(text) from public, anon;
grant execute on function public.is_admin(), public.has_role(text) to authenticated;

-- Signup metadata is editable by users. Privileged provisioning is performed
-- by the existing server-side create-coach-account function after signup.
create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, role, first_name, last_name, phone, member_tier)
  values(new.id, 'member',
    coalesce(nullif(new.raw_user_meta_data ->> 'first_name', ''), 'Member'),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    nullif(new.raw_user_meta_data ->> 'phone', ''), 'standard')
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function private.handle_new_user();
drop function public.handle_new_user();
revoke all on function private.handle_new_user() from public, anon, authenticated;

create or replace function private.protect_profile_fields()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if current_user = 'authenticated' and not private.has_role('admin') then
    if tg_op = 'INSERT' then
      if new.role <> 'member' or new.member_tier <> 'standard' or new.is_blocked then
        raise exception 'PROFILE_FIELDS_PROTECTED' using errcode = '42501';
      end if;
    elsif new.id is distinct from old.id
       or new.role is distinct from old.role
       or new.member_tier is distinct from old.member_tier
       or new.is_blocked is distinct from old.is_blocked
       or new.created_at is distinct from old.created_at then
      raise exception 'PROFILE_FIELDS_PROTECTED' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
create trigger protect_profile_fields before insert or update on public.profiles
for each row execute function private.protect_profile_fields();
revoke all on function private.protect_profile_fields() from public, anon, authenticated;

-- Stable FIFO order even when several inserts have the same timestamp.
create or replace function public.recompute_waitlist_positions(target_session_id uuid)
returns void language plpgsql security invoker set search_path = '' as $$
begin
  with ranked as (
    select id, row_number() over (order by position, created_at, id) as new_position
    from public.waitlists where session_id = target_session_id
  )
  update public.waitlists w set position = ranked.new_position
  from ranked where w.id = ranked.id;
end;
$$;

-- Snapshot the booked price separately from money actually collected.
alter table public.bookings add column quoted_amount_tnd numeric(8,2);
update public.bookings b set quoted_amount_tnd = s.price_tnd
from public.sessions s where s.id = b.session_id;
alter table public.bookings alter column quoted_amount_tnd set not null;
alter table public.bookings add constraint bookings_quote_nonnegative check (quoted_amount_tnd >= 0);
alter table public.bookings drop constraint bookings_unique_member_session;
create unique index bookings_one_active_member_session on public.bookings(member_id, session_id)
where status in ('confirmed', 'attended');

-- Allow a member to read their historical session without creating an RLS
-- cycle between sessions and bookings.
create or replace function private.can_read_booked_session(target_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.bookings
    where session_id = target_id and member_id = (select auth.uid()));
$$;
revoke all on function private.can_read_booked_session(uuid) from public, anon;
grant execute on function private.can_read_booked_session(uuid) to authenticated;
drop policy sessions_select_scheduled_or_staff on public.sessions;
create policy sessions_select_scheduled_or_staff on public.sessions for select to authenticated
using (status = 'scheduled' or coach_id = (select auth.uid())
  or public.is_admin() or private.can_read_booked_session(id));

drop policy sessions_insert_coach_or_admin on public.sessions;
create policy sessions_insert_coach_or_admin on public.sessions for insert to authenticated
with check (public.is_admin() or (public.has_role('coach') and coach_id = (select auth.uid()) and status = 'pending'));

create or replace function private.protect_session_changes()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if current_user = 'authenticated' and not private.has_role('admin') then
    if not private.has_role('coach') then
      raise exception 'STAFF_REQUIRED' using errcode = '42501';
    end if;
    if tg_op = 'UPDATE' and (new.status <> 'cancelled'
      or (to_jsonb(new) - 'status') is distinct from (to_jsonb(old) - 'status')) then
      raise exception 'ADMIN_APPROVAL_REQUIRED' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
create trigger protect_session_changes before insert or update on public.sessions
for each row execute function private.protect_session_changes();
revoke all on function private.protect_session_changes() from public, anon, authenticated;

-- Members mutate bookings only through narrowly scoped RPCs. Staff approvals
-- retain their existing direct update interface under admin RLS.
create or replace function private.protect_booking_writes()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if current_user = 'authenticated' and not private.has_role('admin') then
    raise exception 'USE_RESERVATION_RPC' using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
create trigger protect_booking_writes before insert or update or delete on public.bookings
for each row execute function private.protect_booking_writes();
revoke all on function private.protect_booking_writes() from public, anon, authenticated;

create or replace function private.reserve_session(target_session_id uuid)
returns public.bookings language plpgsql security definer set search_path = '' as $$
declare
  caller_id uuid := auth.uid();
  target public.sessions;
  reservation public.bookings;
begin
  if caller_id is null or not private.has_role('member') then
    raise exception 'ACCOUNT_UNAVAILABLE' using errcode = '42501';
  end if;
  -- Serialize last-place requests and retries against the same session.
  select * into target from public.sessions where id = target_session_id for update;
  if not found then raise exception 'SESSION_UNAVAILABLE'; end if;
  -- Retry after a lost response returns the original reservation.
  select * into reservation from public.bookings
    where member_id = caller_id and session_id = target_session_id and status = 'confirmed';
  if found then return reservation; end if;
  if target.status <> 'scheduled' or target.start_at <= now() or target.price_tnd < 0 then
    raise exception 'SESSION_UNAVAILABLE';
  end if;
  if target.booked_count >= target.max_participants then raise exception 'SESSION_FULL'; end if;
  insert into public.bookings(member_id, session_id, payment_method, payment_status,
    paid_amount_tnd, quoted_amount_tnd, status)
  values(caller_id, target_session_id, 'cash', 'pending', 0, target.price_tnd, 'confirmed')
  returning * into reservation;
  delete from public.waitlists where member_id = caller_id and session_id = target_session_id;
  return reservation;
end;
$$;
revoke all on function private.reserve_session(uuid) from public, anon;
grant execute on function private.reserve_session(uuid) to authenticated;
create or replace function public.reserve_session(target_session_id uuid)
returns public.bookings language sql security invoker set search_path = '' as $$
  select private.reserve_session(target_session_id);
$$;
revoke all on function public.reserve_session(uuid) from public, anon;
grant execute on function public.reserve_session(uuid) to authenticated;

create or replace function private.cancel_reservation(target_booking_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  reservation public.bookings;
  target public.sessions;
  caller_id uuid := auth.uid();
begin
  if caller_id is null then raise exception 'ACCOUNT_UNAVAILABLE' using errcode = '42501'; end if;
  select * into reservation from public.bookings where id = target_booking_id;
  if not found or (reservation.member_id <> caller_id and not private.has_role('admin')) then
    raise exception 'BOOKING_NOT_FOUND' using errcode = '42501';
  end if;
  -- Use the same lock order as reserve_session to avoid deadlocks.
  select * into target from public.sessions where id = reservation.session_id for update;
  select * into reservation from public.bookings where id = target_booking_id for update;
  if reservation.status = 'cancelled' then return; end if;
  if target.start_at <= now() and not private.has_role('admin') then raise exception 'SESSION_STARTED'; end if;
  update public.bookings set status = 'cancelled', cancelled_at = now() where id = target_booking_id;
  -- Do not claim to have issued a refund; real payment reconciliation is separate.
end;
$$;
revoke all on function private.cancel_reservation(uuid) from public, anon;
grant execute on function private.cancel_reservation(uuid) to authenticated;
create or replace function public.cancel_reservation(target_booking_id uuid)
returns void language sql security invoker set search_path = '' as $$
  select private.cancel_reservation(target_booking_id);
$$;
revoke all on function public.cancel_reservation(uuid) from public, anon;
grant execute on function public.cancel_reservation(uuid) to authenticated;

create or replace function private.protect_waitlist_writes()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if current_user = 'authenticated' and not private.has_role('admin') then
    raise exception 'USE_WAITLIST_RPC' using errcode = '42501';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
create trigger protect_waitlist_writes before insert or update or delete on public.waitlists
for each row execute function private.protect_waitlist_writes();
revoke all on function private.protect_waitlist_writes() from public, anon, authenticated;

create or replace function private.join_session_waitlist(target_session_id uuid, preferred_channel text default 'push')
returns public.waitlists language plpgsql security definer set search_path = '' as $$
declare target public.sessions; entry public.waitlists;
begin
  if not private.has_role('member') then raise exception 'ACCOUNT_UNAVAILABLE' using errcode = '42501'; end if;
  if preferred_channel not in ('push','sms','email') then raise exception 'INVALID_CHANNEL'; end if;
  select * into target from public.sessions where id = target_session_id for update;
  if not found or target.status <> 'scheduled' or target.start_at <= now() then raise exception 'SESSION_UNAVAILABLE'; end if;
  select * into entry from public.waitlists where session_id = target_session_id and member_id = auth.uid();
  if found then return entry; end if;
  if exists(select 1 from public.bookings where session_id = target_session_id and member_id = auth.uid() and status = 'confirmed') then
    raise exception 'ALREADY_RESERVED';
  end if;
  insert into public.waitlists(member_id,session_id,notify_channel)
  values(auth.uid(),target_session_id,preferred_channel) returning * into entry;
  return entry;
end;
$$;
revoke all on function private.join_session_waitlist(uuid,text) from public, anon;
grant execute on function private.join_session_waitlist(uuid,text) to authenticated;
create or replace function public.join_session_waitlist(target_session_id uuid, preferred_channel text default 'push')
returns public.waitlists language sql security invoker set search_path = '' as $$
  select private.join_session_waitlist(target_session_id, preferred_channel);
$$;
revoke all on function public.join_session_waitlist(uuid,text) from public, anon;
grant execute on function public.join_session_waitlist(uuid,text) to authenticated;

create or replace function private.leave_session_waitlist(target_entry_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare entry public.waitlists;
begin
  if auth.uid() is null then raise exception 'ACCOUNT_UNAVAILABLE' using errcode = '42501'; end if;
  select * into entry from public.waitlists where id = target_entry_id;
  if not found or (entry.member_id <> auth.uid() and not private.has_role('admin')) then
    raise exception 'WAITLIST_NOT_FOUND' using errcode = '42501';
  end if;
  perform 1 from public.sessions where id = entry.session_id for update;
  delete from public.waitlists where id = target_entry_id;
end;
$$;
revoke all on function private.leave_session_waitlist(uuid) from public, anon;
grant execute on function private.leave_session_waitlist(uuid) to authenticated;
create or replace function public.leave_session_waitlist(target_entry_id uuid)
returns void language sql security invoker set search_path = '' as $$
  select private.leave_session_waitlist(target_entry_id);
$$;
revoke all on function public.leave_session_waitlist(uuid) from public, anon;
grant execute on function public.leave_session_waitlist(uuid) to authenticated;

-- Notifications are committed with cancellation, not emitted beforehand.
create or replace function private.notify_session_cancellation()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'cancelled' and old.status <> 'cancelled' then
    insert into public.notifications(member_id,session_id,title,body)
    select member_id,new.id,'Session cancelled',new.title || ' has been cancelled. Contact the studio about any payment.'
    from public.bookings where session_id = new.id and status = 'confirmed';
  end if;
  return new;
end;
$$;
create trigger notify_session_cancellation after update on public.sessions
for each row execute function private.notify_session_cancellation();
revoke all on function private.notify_session_cancellation() from public, anon, authenticated;

create or replace function private.approve_session_edit(target_request_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare proposal public.session_edit_requests;
begin
  if not private.has_role('admin') then raise exception 'ADMIN_REQUIRED' using errcode = '42501'; end if;
  select * into proposal from public.session_edit_requests where id = target_request_id;
  if not found then raise exception 'REQUEST_NOT_FOUND'; end if;
  perform 1 from public.sessions where id = proposal.session_id for update;
  select * into proposal from public.session_edit_requests where id = target_request_id for update;
  if proposal.status <> 'pending' then raise exception 'REQUEST_ALREADY_REVIEWED'; end if;
  update public.sessions set
    title = coalesce(proposal.proposed_title,title),
    start_at = coalesce(proposal.proposed_start_at,start_at),
    end_at = coalesce(proposal.proposed_end_at,end_at),
    max_participants = coalesce(proposal.proposed_max_participants,max_participants),
    price_tnd = coalesce(proposal.proposed_price_tnd,price_tnd),
    level = coalesce(proposal.proposed_level,level)
  where id = proposal.session_id;
  update public.session_edit_requests set status = 'approved' where id = target_request_id;
end;
$$;
revoke all on function private.approve_session_edit(uuid) from public, anon;
grant execute on function private.approve_session_edit(uuid) to authenticated;
create or replace function public.approve_session_edit(target_request_id uuid)
returns void language sql security invoker set search_path = '' as $$
  select private.approve_session_edit(target_request_id);
$$;
revoke all on function public.approve_session_edit(uuid) from public, anon;
grant execute on function public.approve_session_edit(uuid) to authenticated;


create or replace function private.record_cash_payment(target_booking_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare reservation public.bookings;
begin
  if not private.has_role('admin') then raise exception 'ADMIN_REQUIRED' using errcode = '42501'; end if;
  select * into reservation from public.bookings where id = target_booking_id for update;
  if not found or reservation.payment_method <> 'cash' or reservation.status = 'cancelled' then
    raise exception 'INVALID_PAYMENT';
  end if;
  update public.bookings set payment_status = 'paid', paid_amount_tnd = quoted_amount_tnd
  where id = target_booking_id;
end;
$$;
revoke all on function private.record_cash_payment(uuid) from public, anon;
grant execute on function private.record_cash_payment(uuid) to authenticated;
create or replace function public.record_cash_payment(target_booking_id uuid)
returns void language sql security invoker set search_path = '' as $$
  select private.record_cash_payment(target_booking_id);
$$;
revoke all on function public.record_cash_payment(uuid) from public, anon;
grant execute on function public.record_cash_payment(uuid) to authenticated;

create or replace function private.protect_notification_fields()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if current_user = 'authenticated' and not private.has_role('admin') and
    (to_jsonb(new) - 'is_read') is distinct from (to_jsonb(old) - 'is_read') then
    raise exception 'NOTIFICATION_FIELDS_PROTECTED' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger protect_notification_fields before update on public.notifications
for each row execute function private.protect_notification_fields();
revoke all on function private.protect_notification_fields() from public, anon, authenticated;
create policy notifications_delete_own_or_admin on public.notifications for delete to authenticated
using (member_id = (select auth.uid()) or public.is_admin());

-- Internal trigger helpers are not public API operations.
revoke all on function public.recompute_waitlist_positions(uuid), public.set_waitlist_position(),
  public.resequence_waitlists_after_change(), public.sync_session_booked_count() from public, anon, authenticated;

commit;
