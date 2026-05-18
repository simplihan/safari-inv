
-- 1) Trigger to prevent privilege escalation via direct profile update
CREATE OR REPLACE FUNCTION public.guard_profile_privileged_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Admin/manager can change anything
  IF public.is_admin_or_manager(auth.uid()) THEN
    RETURN NEW;
  END IF;

  -- Otherwise, privileged fields must remain unchanged
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'Not allowed to change status' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'Not allowed to change email' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NEW.sgc_id IS DISTINCT FROM OLD.sgc_id THEN
    RAISE EXCEPTION 'Not allowed to change SGC ID' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NEW.department IS DISTINCT FROM OLD.department THEN
    RAISE EXCEPTION 'Not allowed to change department' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'Not allowed to change id' USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_profile_privileged_fields ON public.profiles;
CREATE TRIGGER guard_profile_privileged_fields
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.guard_profile_privileged_fields();

-- 2) Lock down remaining SECURITY DEFINER helpers from direct API calls
REVOKE EXECUTE ON FUNCTION public.is_admin_or_manager(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.same_department(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.cleanup_old_messages() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.guard_profile_privileged_fields() FROM PUBLIC, anon, authenticated;
