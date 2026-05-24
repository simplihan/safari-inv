import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

export function useDepartments() {
  const [names, setNames] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      const { data, error } = await supabase
        .from("departments")
        .select("name");

      console.log("RAW DEPARTMENTS:", data, error);

      if (error) {
        console.error(error);
        setNames([]);
      } else {
        setNames((data ?? []).map((d: any) => d.name));
      }

      setLoading(false);
    };

    load();
  }, []);

  return { names, loading };
}
