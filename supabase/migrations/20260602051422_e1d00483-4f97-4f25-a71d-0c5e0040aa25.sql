REVOKE EXECUTE ON FUNCTION public.get_email_by_sgc(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_email_by_sgc(text) FROM authenticated;

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM anon;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM authenticated;

REVOKE EXECUTE ON FUNCTION public.is_admin_or_manager(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_admin_or_manager(uuid) FROM authenticated;

REVOKE EXECUTE ON FUNCTION public.is_approved(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_approved(uuid) FROM authenticated;

REVOKE EXECUTE ON FUNCTION public.same_department(uuid, uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.same_department(uuid, uuid) FROM authenticated;

GRANT EXECUTE ON FUNCTION public.get_email_by_sgc(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO service_role;
GRANT EXECUTE ON FUNCTION public.is_admin_or_manager(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.is_approved(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.same_department(uuid, uuid) TO service_role;