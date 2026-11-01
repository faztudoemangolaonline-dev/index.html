create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  service text not null default 'Informações gerais',
  message text not null default '',
  status text not null default 'pending' check (status in ('pending','answered','closed')),
  created_at timestamptz not null default now()
);
alter table public.contact_messages enable row level security;
create policy contact_messages_admin_read on public.contact_messages for select to authenticated using ((select private.is_admin()));
create policy contact_messages_admin_update on public.contact_messages for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy contact_messages_anon_insert on public.contact_messages for insert to anon with check (user_id is null and status = 'pending');
create policy contact_messages_user_insert on public.contact_messages for insert to authenticated with check ((user_id is null or user_id = (select auth.uid())) and status = 'pending');
grant insert on public.contact_messages to anon, authenticated;
grant select, update on public.contact_messages to authenticated;

create policy lost_found_anon_insert_pending on public.lost_found
for insert to anon with check (user_id is null and status = 'pending');

create policy ads_anon_insert_pending on public.ad_submissions
for insert to anon with check (user_id is null and status = 'pending');

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ad-submissions', 'ad-submissions', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy ad_images_pending_upload on storage.objects
for insert to anon, authenticated
with check (bucket_id = 'ad-submissions' and (storage.foldername(name))[1] = 'pending');

create policy ad_images_admin_read on storage.objects
for select to authenticated
using (bucket_id = 'ad-submissions' and (select private.is_admin()));
