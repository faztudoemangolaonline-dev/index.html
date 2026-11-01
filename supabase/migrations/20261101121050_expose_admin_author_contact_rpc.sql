create or replace function public.admin_get_author_phone()
returns text
language sql
stable
security invoker
set search_path = ''
as $$ select private.admin_get_author_phone(); $$;

create or replace function public.admin_set_author_phone(p_phone text)
returns boolean
language sql
security invoker
set search_path = ''
as $$ select private.admin_set_author_phone(p_phone); $$;

revoke all on function public.admin_get_author_phone() from public, anon;
revoke all on function public.admin_set_author_phone(text) from public, anon;
grant execute on function public.admin_get_author_phone() to authenticated;
grant execute on function public.admin_set_author_phone(text) to authenticated;
