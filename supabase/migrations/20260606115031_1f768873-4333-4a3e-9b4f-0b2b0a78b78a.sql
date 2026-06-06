
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Approved users receive scoped realtime" ON realtime.messages;
CREATE POLICY "Approved users receive scoped realtime"
ON realtime.messages
FOR SELECT
TO authenticated
USING (
  private.is_approved(auth.uid())
  AND (
    (payload -> 'data' ->> 'table') IN ('messages','profiles','break_logs','dept_chat_settings')
    OR (
      (payload -> 'data' ->> 'table') = 'departments'
      AND private.is_admin_or_manager(auth.uid())
    )
  )
);
