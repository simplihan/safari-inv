import { createFileRoute, Outlet, useNavigate } from "@tanstack/react-router";
import { useAuth } from "@/hooks/use-auth";
import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/app")({
  component: AppLayout,
});

function AppLayout() {
  const { session, loading, profile, refresh, signOut } = useAuth();
  const navigate = useNavigate();
  const [slow, setSlow] = useState(false);

  useEffect(() => {
    if (loading) return;
    if (!session) navigate({ to: "/login" });
    else if (profile && profile.status !== "approved") navigate({ to: "/login" });
  }, [session, loading, profile, navigate]);

  useEffect(() => {
    if (!session || profile) return;
    const t = setTimeout(() => setSlow(true), 6000);
    return () => clearTimeout(t);
  }, [session, profile]);

  if (loading || !session || !profile) {
    return (
      <div className="min-h-screen grid place-items-center p-6">
        <div className="text-center space-y-4 max-w-sm">
          <Loader2 className="h-6 w-6 animate-spin text-primary mx-auto" />
          {slow && (
            <>
              <p className="text-sm text-muted-foreground">
                Taking longer than expected to load your profile.
              </p>
              <div className="flex gap-2 justify-center">
                <Button size="sm" variant="outline" onClick={() => refresh()}>Retry</Button>
                <Button size="sm" variant="ghost" onClick={async () => { await signOut(); navigate({ to: "/login" }); }}>Sign out</Button>
              </div>
            </>
          )}
        </div>
      </div>
    );
  }

  return (
    <AppShell>
      <Outlet />
    </AppShell>
  );
}