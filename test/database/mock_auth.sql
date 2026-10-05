-- Isolated test fixture only. Never apply this file to a Supabase project.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create table auth.users(id uuid primary key, raw_user_meta_data jsonb default '{}', created_at timestamptz default now());
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
create function auth.role() returns text language sql stable as $$
  select nullif(current_setting('request.jwt.claim.role', true), '');
$$;
grant usage on schema public, auth to anon, authenticated, service_role;
grant execute on function auth.uid(), auth.role() to anon, authenticated, service_role;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
