
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to anon, authenticated;

create table if not exists private.admin_users (
  singleton boolean primary key default true check (singleton = true),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
revoke all on private.admin_users from public, anon, authenticated;

create table if not exists private.admin_bootstrap_emails (
  email text primary key check (email = lower(email)),
  created_at timestamptz not null default now()
);
revoke all on private.admin_bootstrap_emails from public, anon, authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from private.admin_users a
    where a.user_id = (select auth.uid())
  );
$$;
revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to anon, authenticated;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  service text not null,
  details text not null default '',
  status text not null default 'pending' check (status in ('pending','in_progress','approved','rejected','closed')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_code text not null check (plan_code in ('trial_24h','weekly','monthly')),
  amount_aoa numeric(12,2) not null default 0 check (amount_aoa >= 0),
  status text not null default 'pending' check (status in ('pending','active','expired','cancelled','rejected')),
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  amount_aoa numeric(12,2) not null check (amount_aoa > 0),
  method text not null default 'manual',
  reference text,
  proof_url text,
  status text not null default 'pending' check (status in ('pending','confirmed','rejected')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.reseller_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  business_name text not null default '',
  status text not null default 'pending' check (status in ('pending','active','suspended','rejected')),
  commission_percent numeric(5,2) not null default 0 check (commission_percent between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Geral',
  logo_url text,
  stream_url text,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.playlists (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  source_url text,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists private.access_codes (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  secret_value text not null,
  assigned_user_id uuid references auth.users(id) on delete set null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
revoke all on private.access_codes from public, anon, authenticated;

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text not null default '',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  status text not null default 'pending' check (status in ('pending','published','hidden')),
  created_at timestamptz not null default now()
);

create table if not exists public.lost_found (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  item_type text not null check (item_type in ('lost','found')),
  title text not null,
  description text not null default '',
  contact text,
  status text not null default 'pending' check (status in ('pending','published','closed','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.ad_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  business_name text not null,
  contact text not null,
  description text not null default '',
  image_urls text[] not null default '{}',
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.handle_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.profiles (id, full_name, phone)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'full_name', ''),
      coalesce(new.raw_user_meta_data->>'phone', '')
    )
    on conflict (id) do nothing;
  end if;

  if new.email_confirmed_at is not null and new.email is not null then
    lock table private.admin_users in exclusive mode;
    if not exists (select 1 from private.admin_users)
       and exists (
         select 1 from private.admin_bootstrap_emails b
         where b.email = lower(new.email)
       ) then
      insert into private.admin_users(singleton, user_id)
      values (true, new.id)
      on conflict (singleton) do nothing;
      delete from private.admin_bootstrap_emails
      where email = lower(new.email);
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.handle_auth_user_profile() from public, anon, authenticated;

drop trigger if exists on_auth_user_profile_created on auth.users;
create trigger on_auth_user_profile_created
after insert or update of email_confirmed_at on auth.users
for each row execute function public.handle_auth_user_profile();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['profiles','service_requests','subscriptions','reseller_profiles','channels','playlists','app_settings'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

alter table public.profiles enable row level security;
alter table public.service_requests enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payments enable row level security;
alter table public.reseller_profiles enable row level security;
alter table public.channels enable row level security;
alter table public.playlists enable row level security;
alter table public.reviews enable row level security;
alter table public.comments enable row level security;
alter table public.lost_found enable row level security;
alter table public.ad_submissions enable row level security;
alter table public.app_settings enable row level security;

create policy profiles_select_own_or_admin on public.profiles for select to authenticated using (id = (select auth.uid()) or (select private.is_admin()));
create policy profiles_update_own_or_admin on public.profiles for update to authenticated using (id = (select auth.uid()) or (select private.is_admin())) with check (id = (select auth.uid()) or (select private.is_admin()));

create policy service_requests_select_own_or_admin on public.service_requests for select to authenticated using (user_id = (select auth.uid()) or (select private.is_admin()));
create policy service_requests_insert_own on public.service_requests for insert to authenticated with check (user_id = (select auth.uid()));
create policy service_requests_admin_update on public.service_requests for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy subscriptions_select_own_or_admin on public.subscriptions for select to authenticated using (user_id = (select auth.uid()) or (select private.is_admin()));
create policy subscriptions_admin_all on public.subscriptions for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy payments_select_own_or_admin on public.payments for select to authenticated using (user_id = (select auth.uid()) or (select private.is_admin()));
create policy payments_insert_own_pending on public.payments for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending' and reviewed_by is null);
create policy payments_admin_update on public.payments for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy reseller_select_own_or_admin on public.reseller_profiles for select to authenticated using (user_id = (select auth.uid()) or (select private.is_admin()));
create policy reseller_insert_own_pending on public.reseller_profiles for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending' and commission_percent = 0);
create policy reseller_admin_update on public.reseller_profiles for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy channels_public_read on public.channels for select to anon, authenticated using (is_published or (select private.is_admin()));
create policy channels_admin_write on public.channels for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy playlists_admin_only on public.playlists for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy reviews_read_approved_or_own on public.reviews for select to authenticated using (status = 'approved' or user_id = (select auth.uid()) or (select private.is_admin()));
create policy reviews_public_approved on public.reviews for select to anon using (status = 'approved');
create policy reviews_insert_own_pending on public.reviews for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending');
create policy reviews_admin_update on public.reviews for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy comments_read_published_or_own on public.comments for select to authenticated using (status = 'published' or user_id = (select auth.uid()) or (select private.is_admin()));
create policy comments_public_published on public.comments for select to anon using (status = 'published');
create policy comments_insert_own_pending on public.comments for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending');
create policy comments_admin_update on public.comments for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy lost_found_read_published_or_own on public.lost_found for select to authenticated using (status = 'published' or user_id = (select auth.uid()) or (select private.is_admin()));
create policy lost_found_public_published on public.lost_found for select to anon using (status = 'published');
create policy lost_found_insert_own_pending on public.lost_found for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending');
create policy lost_found_admin_update on public.lost_found for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy ads_read_approved_or_own on public.ad_submissions for select to authenticated using (status = 'approved' or user_id = (select auth.uid()) or (select private.is_admin()));
create policy ads_public_approved on public.ad_submissions for select to anon using (status = 'approved');
create policy ads_insert_own_pending on public.ad_submissions for insert to authenticated with check (user_id = (select auth.uid()) and status = 'pending');
create policy ads_admin_update on public.ad_submissions for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

create policy app_settings_admin_only on public.app_settings for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));

grant select on public.channels, public.reviews, public.comments, public.lost_found, public.ad_submissions to anon;
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.service_requests to authenticated;
grant select, insert, update on public.subscriptions to authenticated;
grant select, insert, update on public.payments to authenticated;
grant select, insert, update on public.reseller_profiles to authenticated;
grant select, insert, update, delete on public.channels, public.playlists to authenticated;
grant select, insert, update on public.reviews, public.comments, public.lost_found, public.ad_submissions to authenticated;
grant select, insert, update, delete on public.app_settings to authenticated;
