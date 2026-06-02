-- Allow the access-request form to show department names before login.
GRANT SELECT ON public.departments TO anon;

DROP POLICY IF EXISTS "public can view departments for access requests" ON public.departments;
CREATE POLICY "public can view departments for access requests"
ON public.departments
FOR SELECT
TO anon
USING (true);

-- Let signed-in users read their own profile status even before approval,
-- so login can correctly block pending/rejected users after authentication.
DROP POLICY IF EXISTS "view profile (self / dept / mgr)" ON public.profiles;
CREATE POLICY "view profile (self / dept / mgr)"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid()
  OR public.is_admin_or_manager(auth.uid())
  OR (
    public.is_approved(auth.uid())
    AND public.same_department(auth.uid(), id)
  )
);