
drop policy if exists service_requests_insert_own on public.service_requests;
create policy service_requests_insert_own_pending on public.service_requests
for insert to authenticated
with check (user_id = (select auth.uid()) and status = 'pending' and admin_note is null);

drop policy if exists channels_admin_write on public.channels;
create policy channels_admin_insert on public.channels for insert to authenticated with check ((select private.is_admin()));
create policy channels_admin_update on public.channels for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy channels_admin_delete on public.channels for delete to authenticated using ((select private.is_admin()));

drop policy if exists subscriptions_admin_all on public.subscriptions;
create policy subscriptions_admin_insert on public.subscriptions for insert to authenticated with check ((select private.is_admin()));
create policy subscriptions_admin_update on public.subscriptions for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy subscriptions_admin_delete on public.subscriptions for delete to authenticated using ((select private.is_admin()));

create index if not exists service_requests_user_id_idx on public.service_requests(user_id);
create index if not exists subscriptions_user_id_idx on public.subscriptions(user_id);
create index if not exists subscriptions_created_by_idx on public.subscriptions(created_by);
create index if not exists payments_user_id_idx on public.payments(user_id);
create index if not exists payments_subscription_id_idx on public.payments(subscription_id);
create index if not exists payments_reviewed_by_idx on public.payments(reviewed_by);
create index if not exists reseller_profiles_user_id_idx on public.reseller_profiles(user_id);
create index if not exists reviews_user_id_idx on public.reviews(user_id);
create index if not exists comments_user_id_idx on public.comments(user_id);
create index if not exists lost_found_user_id_idx on public.lost_found(user_id);
create index if not exists ad_submissions_user_id_idx on public.ad_submissions(user_id);
create index if not exists access_codes_assigned_user_id_idx on private.access_codes(assigned_user_id);

revoke all on function public.set_updated_at() from public, anon, authenticated;
