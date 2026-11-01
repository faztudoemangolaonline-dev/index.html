
drop function if exists public.admin_list_access_codes();
drop function if exists public.admin_add_access_code(text,text,uuid,timestamptz);
drop function if exists public.admin_delete_access_code(uuid);

create or replace function private.admin_list_access_codes()
returns table(id uuid, label text, secret_value text, assigned_user_id uuid, expires_at timestamptz, created_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Acesso reservado ao administrador.';
  end if;
  return query
    select c.id, c.label, c.secret_value, c.assigned_user_id, c.expires_at, c.created_at
    from private.access_codes c
    order by c.created_at desc;
end;
$$;

create or replace function private.admin_add_access_code(
  p_label text, p_secret_value text, p_assigned_user_id uuid default null, p_expires_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare new_id uuid;
begin
  if not private.is_admin() then
    raise exception 'Acesso reservado ao administrador.';
  end if;
  if length(trim(coalesce(p_label,''))) = 0 or length(trim(coalesce(p_secret_value,''))) = 0 then
    raise exception 'Indica o nome e o código.';
  end if;
  insert into private.access_codes(label, secret_value, assigned_user_id, expires_at)
  values (trim(p_label), trim(p_secret_value), p_assigned_user_id, p_expires_at)
  returning id into new_id;
  return new_id;
end;
$$;

create or replace function private.admin_delete_access_code(p_code_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Acesso reservado ao administrador.';
  end if;
  delete from private.access_codes where id = p_code_id;
  return found;
end;
$$;

revoke all on function private.admin_list_access_codes() from public, anon;
revoke all on function private.admin_add_access_code(text,text,uuid,timestamptz) from public, anon;
revoke all on function private.admin_delete_access_code(uuid) from public, anon;
grant execute on function private.admin_list_access_codes() to authenticated;
grant execute on function private.admin_add_access_code(text,text,uuid,timestamptz) to authenticated;
grant execute on function private.admin_delete_access_code(uuid) to authenticated;

create or replace function public.admin_list_access_codes()
returns table(id uuid, label text, secret_value text, assigned_user_id uuid, expires_at timestamptz, created_at timestamptz)
language sql
stable
security invoker
set search_path = ''
as $$ select * from private.admin_list_access_codes(); $$;

create or replace function public.admin_add_access_code(
  p_label text, p_secret_value text, p_assigned_user_id uuid default null, p_expires_at timestamptz default null
)
returns uuid
language sql
security invoker
set search_path = ''
as $$ select private.admin_add_access_code(p_label,p_secret_value,p_assigned_user_id,p_expires_at); $$;

create or replace function public.admin_delete_access_code(p_code_id uuid)
returns boolean
language sql
security invoker
set search_path = ''
as $$ select private.admin_delete_access_code(p_code_id); $$;

revoke all on function public.admin_list_access_codes() from public, anon;
revoke all on function public.admin_add_access_code(text,text,uuid,timestamptz) from public, anon;
revoke all on function public.admin_delete_access_code(uuid) from public, anon;
grant execute on function public.admin_list_access_codes() to authenticated;
grant execute on function public.admin_add_access_code(text,text,uuid,timestamptz) to authenticated;
grant execute on function public.admin_delete_access_code(uuid) to authenticated;

create or replace function public.is_current_user_admin()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$ select private.is_admin(); $$;
revoke all on function public.is_current_user_admin() from public, anon;
grant execute on function public.is_current_user_admin() to authenticated;
