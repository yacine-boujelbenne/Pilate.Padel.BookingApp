begin;
-- Signup with hostile metadata must still create a standard member.
insert into auth.users(id, raw_user_meta_data) values
('00000000-0000-0000-0000-000000000001','{"role":"admin","member_tier":"platinum","first_name":"A"}'),
('00000000-0000-0000-0000-000000000002','{"first_name":"B"}'),
('00000000-0000-0000-0000-000000000003','{"first_name":"C"}'),
('00000000-0000-0000-0000-000000000004','{"first_name":"Coach"}'),
('00000000-0000-0000-0000-000000000005','{"first_name":"Admin"}');

do $$ begin
  if (select role from public.profiles where id='00000000-0000-0000-0000-000000000001') <> 'member'
    or (select member_tier from public.profiles where id='00000000-0000-0000-0000-000000000001') <> 'standard' then
    raise exception 'Unsafe signup metadata';
  end if;
end $$;
update public.profiles set role='coach' where id='00000000-0000-0000-0000-000000000004';
update public.profiles set role='admin' where id='00000000-0000-0000-0000-000000000005';
insert into public.sessions(id,coach_id,title,level,start_at,end_at,max_participants,price_tnd) values
('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004','Flow','all',now()+interval '1 day',now()+interval '1 day 1 hour',1,45),
('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000004','Past','all',now()-interval '1 day',now()-interval '23 hours',4,45);

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select set_config('request.jwt.claim.role','authenticated',true);
-- Reading own profile must not recurse.
select role from public.profiles where id=auth.uid();
do $$ begin
  begin
    update public.profiles set role='admin' where id=auth.uid();
    raise exception 'Role escalation accepted';
  exception when insufficient_privilege then null; end;
  begin
    update public.profiles set is_blocked=true where id=auth.uid();
    raise exception 'Protected profile field accepted';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.bookings(member_id,session_id,payment_method,payment_status,paid_amount_tnd,quoted_amount_tnd)
    values(auth.uid(),'10000000-0000-0000-0000-000000000001','card','paid',1,1);
    raise exception 'Client payment fabrication accepted';
  exception when insufficient_privilege then null; end;
end $$;
select public.reserve_session('10000000-0000-0000-0000-000000000001');
-- Idempotent retry, even with the last place taken.
select public.reserve_session('10000000-0000-0000-0000-000000000001');
do $$ begin
  if (select count(*) from public.bookings where member_id=auth.uid() and status='confirmed') <> 1 then raise exception 'Duplicate reservation'; end if;
  if (select quoted_amount_tnd from public.bookings where member_id=auth.uid() and status='confirmed') <> 45 then raise exception 'Incorrect price snapshot'; end if;
  if (select paid_amount_tnd from public.bookings where member_id=auth.uid() and status='confirmed') <> 0 then raise exception 'Cash marked collected'; end if;
  begin
    update public.bookings set payment_status='paid' where member_id=auth.uid();
    raise exception 'Client payment mutation accepted';
  exception when insufficient_privilege then null; end;
  begin
    perform public.reserve_session('10000000-0000-0000-0000-000000000002');
    raise exception 'Past session reserved';
  exception when raise_exception then
    if sqlerrm <> 'SESSION_UNAVAILABLE' then raise; end if;
  end;
end $$;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$ begin
  begin
    perform public.reserve_session('10000000-0000-0000-0000-000000000001');
    raise exception 'Full session accepted';
  exception when raise_exception then
    if sqlerrm <> 'SESSION_FULL' then raise; end if;
  end;
end $$;
select public.join_session_waitlist('10000000-0000-0000-0000-000000000001','push');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
select public.join_session_waitlist('10000000-0000-0000-0000-000000000001','email');
do $$ begin
  if (select position from public.waitlists where member_id=auth.uid()) <> 2 then raise exception 'Incorrect queue position under RLS'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select public.leave_session_waitlist((select id from public.waitlists where member_id=auth.uid()));
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
do $$ begin
  if (select position from public.waitlists where member_id=auth.uid()) <> 1 then raise exception 'Queue not resequenced'; end if;
end $$;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select public.cancel_reservation((select id from public.bookings where member_id=auth.uid() and status='confirmed'));
select public.reserve_session('10000000-0000-0000-0000-000000000001');
select public.cancel_reservation((select id from public.bookings where member_id=auth.uid() and status='confirmed'));
select public.reserve_session('10000000-0000-0000-0000-000000000001');
do $$ begin
  if (select count(*) from public.bookings where member_id=auth.uid() and status='cancelled') <> 2 then raise exception 'Cancellation history lost'; end if;
  if (select booked_count from public.sessions where id='10000000-0000-0000-0000-000000000001') <> 1 then raise exception 'Capacity count drift'; end if;
end $$;


-- Ownership and staff authority are checked inside the RPC, not only in UI.
reset role;
create temporary table test_booking_id as select id from public.bookings where member_id='00000000-0000-0000-0000-000000000001' and status='confirmed';
grant select on test_booking_id to authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$ begin
  begin
    perform public.cancel_reservation((select id from test_booking_id));
    raise exception 'Cancelled another member reservation';
  exception when insufficient_privilege then null; end;
  begin
    perform public.record_cash_payment((select id from test_booking_id));
    raise exception 'Member collected cash';
  exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000005',true);
select public.record_cash_payment((select id from test_booking_id));
do $$ begin
  if (select paid_amount_tnd from public.bookings where id=(select id from test_booking_id)) <> 45 then raise exception 'Incorrect cash collection'; end if;
end $$;
reset role;
insert into public.session_edit_requests(id,session_id,coach_id,proposed_start_at,proposed_end_at)
values('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
'00000000-0000-0000-0000-000000000004',now()+interval '3 days',now()+interval '2 days');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000005',true);
do $$ begin
  begin
    perform public.approve_session_edit('20000000-0000-0000-0000-000000000001');
    raise exception 'Invalid session times accepted';
  exception when check_violation then null; end;
  if (select status from public.session_edit_requests where id='20000000-0000-0000-0000-000000000001') <> 'pending' then
    raise exception 'Failed edit request was marked approved';
  end if;
end $$;

-- Coach can cancel, but cannot bypass admin approval.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000004',true);
do $$ begin
  begin
    update public.sessions set title='Unapproved edit' where id='10000000-0000-0000-0000-000000000001';
    raise exception 'Coach bypassed approval';
  exception when insufficient_privilege then null; end;
end $$;
update public.sessions set status='cancelled' where id='10000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ begin
  if (select count(*) from public.notifications where member_id=auth.uid()) <> 1 then raise exception 'Missing cancellation notification'; end if;
  if (select count(*) from public.sessions where id='10000000-0000-0000-0000-000000000001') <> 1 then raise exception 'Historical session hidden'; end if;
end $$;

reset role;
update public.profiles set is_blocked=true where id='00000000-0000-0000-0000-000000000002';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$ begin
  begin
    perform public.reserve_session('10000000-0000-0000-0000-000000000001');
    raise exception 'Blocked account reserved';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
