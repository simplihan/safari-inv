import { createMiddleware } from "@tanstack/react-start";
import { supabase } from "@/integrations/supabase/client";

/**
 * Client-side function middleware that attaches the current Supabase
 * access token to outgoing serverFn RPC requests as
 * `Authorization: Bearer <token>`.
 */
export const attachSupabaseAuth = createMiddleware({ type: "function" })
  .client(async ({ next }) => {
    let headers: Record<string, string> = {};
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (session?.access_token) {
        headers = { Authorization: `Bearer ${session.access_token}` };
      }
    } catch {
      // No session available — proceed unauthenticated.
    }
    return next({ sendContext: {}, headers });
  });
