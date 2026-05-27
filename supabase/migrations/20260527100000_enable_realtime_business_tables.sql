-- ============================================================
-- Migration: Enable Supabase Realtime for critical business tables.
--
-- Without this, leavesRealtimeProvider / tasksRealtimeProvider
-- subscribe but never receive events, so the admin panel only
-- updates on a manual pull-to-refresh instead of instantly.
-- ============================================================

-- Add the tables to the default Realtime publication.
-- IF they are already present the statement is a no-op.
DO $$
BEGIN
  -- leave_requests: admins must see employee submissions in real time
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime'
       AND schemaname = 'public'
       AND tablename  = 'leave_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.leave_requests;
  END IF;

  -- tasks: employees must see new assignments instantly
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime'
       AND schemaname = 'public'
       AND tablename  = 'tasks'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
  END IF;

  -- announcements: employees receive company-wide announcements in real time
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime'
       AND schemaname = 'public'
       AND tablename  = 'announcements'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
  END IF;
END
$$;
