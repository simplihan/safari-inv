-- 1. Remove client-side INSERT on audit_logs. The log_audit_change trigger is
-- SECURITY DEFINER and continues to write entries; service role also bypasses RLS.
DROP POLICY IF EXISTS "Self can insert audit logs" ON public.audit_logs;

-- 2. Replace realtime.messages policy to explicitly authorize dept_chat_settings
-- and departments change events.
DROP POLICY IF EXISTS "authenticated can receive own realtime" ON realtime.messages;

CREATE POLICY "authenticated can receive own realtime"
ON realtime.messages
FOR SELECT
TO authenticated
USING (
  private.is_approved(auth.uid())
  AND extension = 'postgres_changes'
  AND (
    (
      ((payload -> 'data') ->> 'table') = 'profiles'
      AND (
        ((((payload -> 'data') -> 'record') ->> 'id'))::uuid = auth.uid()
        OR private.is_admin_or_manager(auth.uid())
        OR private.same_department(auth.uid(), ((((payload -> 'data') -> 'record') ->> 'id'))::uuid)
      )
    )
    OR (
      ((payload -> 'data') ->> 'table') = 'break_logs'
      AND (
        ((((payload -> 'data') -> 'record') ->> 'user_id'))::uuid = auth.uid()
        OR private.is_admin_or_manager(auth.uid())
        OR private.same_department(auth.uid(), ((((payload -> 'data') -> 'record') ->> 'user_id'))::uuid)
      )
    )
    OR (
      ((payload -> 'data') ->> 'table') = 'messages'
      AND (
        ((((payload -> 'data') -> 'record') ->> 'sender_id'))::uuid = auth.uid()
        OR ((((payload -> 'data') -> 'record') ->> 'recipient_id'))::uuid = auth.uid()
      )
    )
    OR (
      ((payload -> 'data') ->> 'table') = 'dept_chat_settings'
      AND (
        private.is_admin_or_manager(auth.uid())
        OR ((((payload -> 'data') -> 'record') ->> 'department'))
            = (SELECT department FROM public.profiles WHERE id = auth.uid())
      )
    )
    OR (
      ((payload -> 'data') ->> 'table') = 'departments'
    )
  )
);

-- 3. Pin search_path on email-queue helper functions.
ALTER FUNCTION public.read_email_batch(text, integer, integer) SET search_path = public;
ALTER FUNCTION public.delete_email(text, bigint) SET search_path = public;
ALTER FUNCTION public.move_to_dlq(text, text, bigint, jsonb) SET search_path = public;
ALTER FUNCTION public.enqueue_email(text, jsonb) SET search_path = public;