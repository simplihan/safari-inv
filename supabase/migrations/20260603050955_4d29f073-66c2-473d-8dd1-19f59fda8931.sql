
REVOKE ALL ON FUNCTION public.auto_close_stale_breaks() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.cleanup_old_break_logs() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.auto_close_stale_breaks() TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_old_break_logs() TO service_role;
