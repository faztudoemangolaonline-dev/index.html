create index if not exists music_feedback_user_id_idx
  on public.music_feedback(user_id);

create index if not exists music_tracks_created_by_idx
  on public.music_tracks(created_by);

alter policy "Only sole admin manages author profile"
  on public.site_profile_settings
  using ((select auth.uid()) = 'fe1f27ed-569f-46a6-89ed-992a8ff3a68d'::uuid)
  with check ((select auth.uid()) = 'fe1f27ed-569f-46a6-89ed-992a8ff3a68d'::uuid);
