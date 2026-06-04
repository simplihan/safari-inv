import { createStart, createMiddleware } from "@tanstack/react-start";
import { attachSupabaseAuth } from "@/integrations/supabase/auth-attacher";

const middleware = createMiddleware().server(async ({ next, context }) => {
  const ctx = await attachSupabaseAuth(context);
  return next({ context: ctx });
});

export default createStart({
  middleware: [middleware],
});
