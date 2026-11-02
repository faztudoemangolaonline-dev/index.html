-- Bind IPTV subscriptions to a generated browser reader identity.
alter table public.iptv_reader_devices add column if not exists device_key_hash text;
create unique index if not exists iptv_reader_devices_device_key_hash_uidx on public.iptv_reader_devices(device_key_hash) where device_key_hash is not null;
drop function if exists public.iptv_register_reader(text,text,text);
create or replace function public.iptv_register_reader(p_device_name text,p_login_identifier text,p_device_type text default 'iptv',p_device_key text default null)
returns uuid language plpgsql security definer set search_path=public,private,auth as $$
declare v_id uuid; v_owner uuid; v_hash text;
begin
 if auth.uid() is null then raise exception 'É necessário iniciar sessão.'; end if;
 if length(trim(coalesce(p_device_name,'')))<2 then raise exception 'Indique um nome para o leitor.'; end if;
 if length(trim(coalesce(p_login_identifier,'')))<3 then raise exception 'Identificação do leitor inválida.'; end if;
 if p_device_key is null or p_device_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then raise exception 'Identificador local do leitor inválido.'; end if;
 v_hash:=md5(lower(p_device_key));
 select id,user_id into v_id,v_owner from public.iptv_reader_devices where device_key_hash=v_hash for update;
 if found then
   if v_owner<>auth.uid() then raise exception 'Este leitor já está associado a outra conta.'; end if;
   update public.iptv_reader_devices set device_name=trim(p_device_name),login_identifier=trim(p_login_identifier),device_type=coalesce(nullif(p_device_type,''),'iptv'),is_active=true,updated_at=now() where id=v_id;
   return v_id;
 end if;
 insert into public.iptv_reader_devices(user_id,device_name,login_identifier,device_type,device_key_hash)
 values(auth.uid(),trim(p_device_name),trim(p_login_identifier),coalesce(nullif(p_device_type,''),'iptv'),v_hash) returning id into v_id;
 return v_id;
end $$;
drop function if exists public.iptv_my_access();
create function public.iptv_my_access(p_device_key text)
returns table(subscription_id uuid,plan_code text,status text,starts_at timestamptz,ends_at timestamptz,reader_device_id uuid,reader_name text,reader_login text,playlist_id uuid,playlist_name text)
language plpgsql security definer set search_path=public,private,auth as $$
declare v_hash text;
begin
 if auth.uid() is null then raise exception 'É necessário iniciar sessão.'; end if;
 if p_device_key is null or p_device_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then raise exception 'Identificador do leitor inválido.'; end if;
 v_hash:=md5(lower(p_device_key));
 return query select s.id,s.plan_code,case when s.status='active' and s.ends_at is not null and s.ends_at<=now() then 'expired' else s.status end,
 s.starts_at,s.ends_at,d.id,d.device_name,d.login_identifier,p.id,p.name
 from public.subscriptions s join public.iptv_reader_devices d on d.id=s.reader_device_id and d.user_id=s.user_id
 left join public.playlists p on p.id=s.playlist_id
 where s.user_id=auth.uid() and d.device_key_hash=v_hash and d.is_active order by s.created_at desc;
end $$;
drop function if exists public.iptv_admin_list_playlists();
create function public.iptv_admin_list_playlists()
returns table(id uuid,name text,is_active boolean,description text,source_url text)
language sql security definer set search_path=public,private as $$
 select p.id,p.name,p.is_active,p.description,p.source_url from public.playlists p
 where coalesce(private.is_admin(),false) order by p.name;
$$;
revoke all on function public.iptv_register_reader(text,text,text,text) from public,anon;
grant execute on function public.iptv_register_reader(text,text,text,text) to authenticated;
revoke all on function public.iptv_my_access(text) from public,anon;
grant execute on function public.iptv_my_access(text) to authenticated;
revoke all on function public.iptv_admin_list_playlists() from public,anon;
grant execute on function public.iptv_admin_list_playlists() to authenticated;
