
-- 1) Allow the privileged-field trigger to pass when there is no auth context
-- (i.e. server functions calling via the admin service role). RLS / route
-- guards still gate who can invoke those server functions.
CREATE OR REPLACE FUNCTION public.guard_profile_privileged_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL OR public.is_admin_or_manager(auth.uid()) THEN
    RETURN NEW;
  END IF;

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

-- 2) Notifications-on-by-default per user
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS notif_enabled boolean NOT NULL DEFAULT true;

-- 3) Login events (device + IP)
CREATE TABLE IF NOT EXISTS public.login_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  ip text,
  user_agent text,
  device text,
  browser text,
  os text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS login_events_user_created_idx
  ON public.login_events (user_id, created_at DESC);

ALTER TABLE public.login_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "view own or dept login events" ON public.login_events;
CREATE POLICY "view own or dept login events"
ON public.login_events FOR SELECT TO authenticated
USING (
  public.is_admin_or_manager(auth.uid())
  OR (
    public.is_approved(auth.uid())
    AND (user_id = auth.uid() OR public.same_department(auth.uid(), user_id))
  )
);

DROP POLICY IF EXISTS "insert own login event" ON public.login_events;
CREATE POLICY "insert own login event"
ON public.login_events FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());
