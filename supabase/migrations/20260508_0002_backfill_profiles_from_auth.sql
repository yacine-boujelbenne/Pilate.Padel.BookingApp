-- Backfill missing profiles from auth.users and ensure signup trigger exists.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    role,
    first_name,
    last_name,
    phone,
    speciality,
    member_tier
  ) values (
    new.id,
    case lower(coalesce(new.raw_user_meta_data ->> 'role', 'member'))
      when 'admin' then 'admin'
      when 'coach' then 'coach'
      else 'member'
    end,
    coalesce(nullif(new.raw_user_meta_data ->> 'first_name', ''), 'User'),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    nullif(new.raw_user_meta_data ->> 'phone', ''),
    nullif(new.raw_user_meta_data ->> 'speciality', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'member_tier', ''), 'standard')
  )
  on conflict (id) do update
  set
    role = excluded.role,
    first_name = case
      when public.profiles.first_name is null or public.profiles.first_name = '' then excluded.first_name
      else public.profiles.first_name
    end,
    last_name = case
      when public.profiles.last_name is null then excluded.last_name
      else public.profiles.last_name
    end,
    phone = coalesce(public.profiles.phone, excluded.phone),
    speciality = coalesce(public.profiles.speciality, excluded.speciality),
    member_tier = coalesce(public.profiles.member_tier, excluded.member_tier);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.profiles (
  id,
  role,
  first_name,
  last_name,
  phone,
  speciality,
  member_tier,
  created_at
)
select
  u.id,
  case lower(coalesce(u.raw_user_meta_data ->> 'role', 'member'))
    when 'admin' then 'admin'
    when 'coach' then 'coach'
    else 'member'
  end as role,
  coalesce(nullif(u.raw_user_meta_data ->> 'first_name', ''), 'User') as first_name,
  coalesce(u.raw_user_meta_data ->> 'last_name', '') as last_name,
  nullif(u.raw_user_meta_data ->> 'phone', '') as phone,
  nullif(u.raw_user_meta_data ->> 'speciality', '') as speciality,
  coalesce(nullif(u.raw_user_meta_data ->> 'member_tier', ''), 'standard') as member_tier,
  coalesce(u.created_at, now()) as created_at
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- Optional normalization for legacy rows.
update public.profiles
set role = lower(role)
where role in ('MEMBER', 'COACH', 'ADMIN', 'Member', 'Coach', 'Admin');
