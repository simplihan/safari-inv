
-- 1) audit_logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NULL,
  action text NOT NULL,
  entity text NOT NULL,
  entity_id text NULL,
  payload jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT ON public.audit_logs TO authenticated;
GRANT ALL ON public.audit_logs TO service_role;

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins read audit logs" ON public.audit_logs;
CREATE POLICY "Admins read audit logs" ON public.audit_logs
FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.user_roles ur
  WHERE ur.user_id = auth.uid() AND ur.role = 'admin'
));

DROP POLICY IF EXISTS "Authenticated can insert audit logs" ON public.audit_logs;
CREATE POLICY "Authenticated can insert audit logs" ON public.audit_logs
FOR INSERT TO authenticated WITH CHECK (true);

CREATE INDEX IF NOT EXISTS audit_logs_created_at_idx ON public.audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_entity_idx ON public.audit_logs (entity, entity_id);

-- 2) Generic trigger function
CREATE OR REPLACE FUNCTION public.log_audit_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  entity_name text := TG_ARGV[0];
  rec_id text;
  payload_json jsonb;
BEGIN
  IF TG_OP = 'DELETE' THEN
    rec_id := COALESCE((to_jsonb(OLD)->>'id'), '');
    payload_json := jsonb_build_object('old', to_jsonb(OLD));
  ELSIF TG_OP = 'UPDATE' THEN
    rec_id := COALESCE((to_jsonb(NEW)->>'id'), '');
    payload_json := jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW));
  ELSE
    rec_id := COALESCE((to_jsonb(NEW)->>'id'), '');
    payload_json := jsonb_build_object('new', to_jsonb(NEW));
  END IF;

  INSERT INTO public.audit_logs (actor_id, action, entity, entity_id, payload)
  VALUES (auth.uid(), TG_OP, entity_name, rec_id, payload_json);

  RETURN COALESCE(NEW, OLD);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.log_audit_change() FROM PUBLIC, anon, authenticated;

-- 3) Triggers
DROP TRIGGER IF EXISTS audit_profiles ON public.profiles;
CREATE TRIGGER audit_profiles
AFTER INSERT OR UPDATE OR DELETE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.log_audit_change('profiles');

DROP TRIGGER IF EXISTS audit_break_logs ON public.break_logs;
CREATE TRIGGER audit_break_logs
AFTER INSERT OR UPDATE OR DELETE ON public.break_logs
FOR EACH ROW EXECUTE FUNCTION public.log_audit_change('break_logs');

DROP TRIGGER IF EXISTS audit_departments ON public.departments;
CREATE TRIGGER audit_departments
AFTER INSERT OR UPDATE OR DELETE ON public.departments
FOR EACH ROW EXECUTE FUNCTION public.log_audit_change('departments');

DROP TRIGGER IF EXISTS audit_user_roles ON public.user_roles;
CREATE TRIGGER audit_user_roles
AFTER INSERT OR UPDATE OR DELETE ON public.user_roles
FOR EACH ROW EXECUTE FUNCTION public.log_audit_change('user_roles');

-- 4) Retention: cleanup functions for login_events and audit_logs
CREATE OR REPLACE FUNCTION public.cleanup_old_login_events()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM public.login_events WHERE created_at < now() - INTERVAL '90 days';
$$;
REVOKE EXECUTE ON FUNCTION public.cleanup_old_login_events() FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.cleanup_old_audit_logs()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM public.audit_logs WHERE created_at < now() - INTERVAL '90 days';
$$;
REVOKE EXECUTE ON FUNCTION public.cleanup_old_audit_logs() FROM PUBLIC, anon, authenticated;

-- 5) Daily pg_cron purge (3am UTC)
SELECT cron.unschedule('pulse-daily-retention') WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'pulse-daily-retention');

SELECT cron.schedule(
  'pulse-daily-retention',
  '0 3 * * *',
  $$
    SELECT public.cleanup_old_break_logs();
    SELECT public.cleanup_old_messages();
    SELECT public.cleanup_old_login_events();
    SELECT public.cleanup_old_audit_logs();
  $$
);
