GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_or_manager(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_approved(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.same_department(uuid, uuid) TO authenticated;