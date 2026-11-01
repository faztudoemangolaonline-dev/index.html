create table if not exists private.author_private_contact (
  profile_key text primary key default 'author' check (profile_key = 'author'),
  phone text not null default '',
  updated_at timestamptz not null default now()
);
alter table private.author_private_contact enable row level security;
revoke all on private.author_private_contact from public, anon, authenticated;

insert into private.author_private_contact(profile_key, phone)
values ('author', '+244 921 807 729')
on conflict (profile_key) do update
set phone = excluded.phone, updated_at = now();

create or replace function private.admin_get_author_phone()
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_phone text;
begin
  if not private.is_admin() then
    raise exception 'Acesso reservado ao administrador.';
  end if;
  select phone into v_phone
  from private.author_private_contact
  where profile_key = 'author';
  return coalesce(v_phone, '');
end;
$$;

create or replace function private.admin_set_author_phone(p_phone text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_admin() then
    raise exception 'Acesso reservado ao administrador.';
  end if;
  if length(trim(coalesce(p_phone, ''))) > 40 then
    raise exception 'O contacto não pode ultrapassar 40 caracteres.';
  end if;
  insert into private.author_private_contact(profile_key, phone, updated_at)
  values ('author', trim(coalesce(p_phone, '')), now())
  on conflict (profile_key) do update
    set phone = excluded.phone, updated_at = now();
  return true;
end;
$$;

revoke all on function private.admin_get_author_phone() from public, anon;
revoke all on function private.admin_set_author_phone(text) from public, anon;
grant execute on function private.admin_get_author_phone() to authenticated;
grant execute on function private.admin_set_author_phone(text) to authenticated;
