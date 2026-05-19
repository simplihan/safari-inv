import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";
import { getRequestIP, getRequestHeader } from "@tanstack/react-start/server";

function parseUA(ua: string) {
  const u = ua.toLowerCase();
  const os =
    u.includes("windows") ? "Windows" :
    u.includes("mac os") || u.includes("macintosh") ? "macOS" :
    u.includes("android") ? "Android" :
    u.includes("iphone") || u.includes("ipad") || u.includes("ios") ? "iOS" :
    u.includes("linux") ? "Linux" : "Unknown";
  const browser =
    u.includes("edg/") ? "Edge" :
    u.includes("opr/") || u.includes("opera") ? "Opera" :
    u.includes("chrome") && !u.includes("edg/") ? "Chrome" :
    u.includes("firefox") ? "Firefox" :
    u.includes("safari") && !u.includes("chrome") ? "Safari" : "Browser";
  const device =
    u.includes("mobile") || u.includes("iphone") || u.includes("android") ? "Mobile" :
    u.includes("ipad") || u.includes("tablet") ? "Tablet" : "Desktop";
  return { os, browser, device };
}

export const recordLoginEvent = createServerFn({ method: "POST" })
  .middleware([requireSupabaseAuth])
  .inputValidator((input) => z.object({ user_agent: z.string().max(500).optional() }).parse(input ?? {}))
  .handler(async ({ data, context }) => {
    const { supabase, userId } = context;
    let ip: string | null = null;
    let uaHeader: string | null = null;
    try {
      ip = getRequestIP({ xForwardedFor: true }) ?? null;
      uaHeader = getRequestHeader("user-agent") ?? null;
    } catch { /* ignore */ }
    const ua = data.user_agent ?? uaHeader ?? "";
    const { os, browser, device } = parseUA(ua);
    await supabase.from("login_events").insert({
      user_id: userId,
      ip,
      user_agent: ua,
      device,
      browser,
      os,
    });
    return { ok: true };
  });