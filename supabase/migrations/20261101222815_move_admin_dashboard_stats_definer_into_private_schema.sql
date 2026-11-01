CREATE OR REPLACE FUNCTION private.admin_dashboard_stats()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.is_admin() THEN
    RAISE EXCEPTION 'Acesso reservado ao administrador';
  END IF;
  RETURN jsonb_build_object(
    'registered_users',(SELECT count(*) FROM auth.users),
    'profiles',(SELECT count(*) FROM public.profiles),
    'clients_with_subscriptions',(SELECT count(DISTINCT user_id) FROM public.subscriptions),
    'active_subscriptions',(SELECT count(*) FROM public.subscriptions WHERE status='active' AND (ends_at IS NULL OR ends_at > now())),
    'pending_subscriptions',(SELECT count(*) FROM public.subscriptions WHERE status='pending'),
    'reviews_total',(SELECT count(*) FROM public.reviews),
    'reviews_average',(SELECT coalesce(round(avg(rating)::numeric,2),0) FROM public.reviews WHERE status='approved'),
    'comments_total',(SELECT count(*) FROM public.comments),
    'pending_comments',(SELECT count(*) FROM public.comments WHERE status='pending'),
    'payments_pending',(SELECT count(*) FROM public.payments WHERE status='pending'),
    'payments_confirmed',(SELECT count(*) FROM public.payments WHERE status='confirmed'),
    'service_requests_pending',(SELECT count(*) FROM public.service_requests WHERE status='pending'),
    'music_tracks',(SELECT count(*) FROM public.music_tracks),
    'music_plays',(SELECT count(*) FROM public.music_events WHERE event_type='play'),
    'music_downloads',(SELECT count(*) FROM public.music_events WHERE event_type='download'),
    'music_feedback_total',(SELECT count(*) FROM public.music_feedback),
    'music_feedback_pending',(SELECT count(*) FROM public.music_feedback WHERE status='pending'),
    'music_feedback_average',(SELECT coalesce(round(avg(rating)::numeric,2),0) FROM public.music_feedback WHERE status='approved' AND rating IS NOT NULL)
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.admin_dashboard_stats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.admin_dashboard_stats() TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_dashboard_stats()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT private.admin_dashboard_stats();
$function$;

REVOKE ALL ON FUNCTION public.admin_dashboard_stats() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_dashboard_stats() TO authenticated;
