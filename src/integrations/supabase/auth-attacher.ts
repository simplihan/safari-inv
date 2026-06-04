import { createMiddleware } from "@tanstack/react-start";
import { createClient } from "@/integrations/supabase/client";

export const attachSupabaseAuth = createMiddleware().server(async ({ next }) => {
  const supabase = createClient();

  const {
    data: { session },
  } = await supabase.auth.getSession();

  return next({
    context: {
      supabaseSession: session ?? null,
      user: session?.user ?? null,
    },
  });
});
