create index if not exists music_feedback_user_id_idx
  on public.music_feedback(user_id);
create index if not exists music_tracks_created_by_idx
  on public.music_tracks(created_by);
