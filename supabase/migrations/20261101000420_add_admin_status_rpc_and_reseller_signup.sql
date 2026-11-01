
create or replace function public.is_current_user_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin();
$$;
revoke all on function public.is_current_user_admin() from public, anon;
grant execute on function public.is_current_user_admin() to authenticated;

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

    if lower(coalesce(new.raw_user_meta_data->>'account_type','')) = 'reseller' then
      insert into public.reseller_profiles(user_id, business_name, status, commission_percent)
      values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'pending', 0)
      on conflict (user_id) do nothing;
    end if;
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
