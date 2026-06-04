-- Phase 1 fix: departments table missing GRANTs so register dropdown was empty
GRANT SELECT ON public.departments TO anon, authenticated;
GRANT ALL ON public.departments TO service_role;

-- Backfill: ensure every profile has notif_enabled set (default true)
UPDATE public.profiles SET notif_enabled = true WHERE notif_enabled IS NULL;