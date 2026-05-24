import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

export function useDepartments() {
  const [names, setNames] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDepartments = async () => {
      const { data, error } = await supabase
        .from("departments")
        .select("name");

      if (error) {
        console.log("Department error:", error);
        setNames([]);
      } else {
        setNames(data?.map((d: any) => d.name) || []);
      }

      setLoading(false);
    };

    fetchDepartments();
  }, []);

  return { names, loading };
}
