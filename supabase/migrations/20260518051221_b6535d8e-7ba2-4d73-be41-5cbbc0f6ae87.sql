
-- Restore EXECUTE for helpers that are called from RLS policies.
-- These are SECURITY DEFINER, but Postgres still requires EXECUTE on the caller.
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_or_manager(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.same_department(uuid, uuid) TO authenticated;

-- Dynamic departments
CREATE TABLE IF NOT EXISTS public.departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anyone signed in can view departments"
  ON public.departments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "admin manages departments"
  ON public.departments FOR ALL
  TO authenticated
  USING (public.has_role(auth.uid(), 'admin'))
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TRIGGER touch_departments_updated_at
BEFORE UPDATE ON public.departments
FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Cascade renames to dependent text columns
CREATE OR REPLACE FUNCTION public.cascade_department_rename()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.name IS DISTINCT FROM OLD.name THEN
    UPDATE public.profiles SET department = NEW.name WHERE department = OLD.name;
    UPDATE public.dept_chat_settings SET department = NEW.name WHERE department = OLD.name;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.cascade_department_rename() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER cascade_department_rename
AFTER UPDATE ON public.departments
FOR EACH ROW EXECUTE FUNCTION public.cascade_department_rename();

-- Seed the existing four
INSERT INTO public.departments (name) VALUES
  ('Inventory'), ('Purchase'), ('Admin'), ('Customer Service')
ON CONFLICT (name) DO NOTHING;
