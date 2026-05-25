-- ============================================================
-- Migration: Función helper + tablas tasks, leave_requests,
--            alert_logs, announcements + políticas RLS
-- ============================================================

-- ── 0. Función helper: obtener company_id del usuario actual ──────────────────

CREATE OR REPLACE FUNCTION public.get_current_user_company_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    NULLIF(TRIM((auth.jwt()->'app_metadata'->>'company_id')::text),  ''),
    NULLIF(TRIM((auth.jwt()->'user_metadata'->>'company_id')::text), ''),
    (SELECT company_id::text FROM public.employees WHERE id::text = auth.uid()::text LIMIT 1)
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_current_user_company_id() TO authenticated;

-- ── 1. tasks ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.tasks (
  id              TEXT PRIMARY KEY,
  company_id      TEXT NOT NULL,
  assigned_to_id  TEXT NOT NULL,
  created_by_id   TEXT NOT NULL DEFAULT '',
  title           TEXT NOT NULL DEFAULT '',
  description     TEXT,
  status          TEXT NOT NULL DEFAULT 'PENDING',
  priority        TEXT NOT NULL DEFAULT 'NORMAL',
  due_date        TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tasks_select_company" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_admin"   ON public.tasks;
DROP POLICY IF EXISTS "tasks_update"         ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_admin"   ON public.tasks;

CREATE POLICY "tasks_select_company"
  ON public.tasks FOR SELECT TO authenticated
  USING (company_id = public.get_current_user_company_id());

CREATE POLICY "tasks_insert_admin"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (company_id = public.get_current_user_company_id());

CREATE POLICY "tasks_update"
  ON public.tasks FOR UPDATE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      assigned_to_id = auth.uid()::text
      OR (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
    )
  )
  WITH CHECK (company_id = public.get_current_user_company_id());

CREATE POLICY "tasks_delete_admin"
  ON public.tasks FOR DELETE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
    )
  );

-- ── 2. leave_requests ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.leave_requests (
  id             TEXT PRIMARY KEY,
  employee_id    TEXT NOT NULL,
  company_id     TEXT NOT NULL,
  type           TEXT NOT NULL DEFAULT 'PERSONAL',
  status         TEXT NOT NULL DEFAULT 'PENDING',
  start_date     TIMESTAMPTZ NOT NULL,
  end_date       TIMESTAMPTZ NOT NULL,
  reason         TEXT,
  reviewed_by_id TEXT,
  review_note    TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "leave_requests_select_company" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_insert_self"    ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_update_admin"   ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_delete"         ON public.leave_requests;

CREATE POLICY "leave_requests_select_company"
  ON public.leave_requests FOR SELECT TO authenticated
  USING (company_id = public.get_current_user_company_id());

CREATE POLICY "leave_requests_insert_self"
  ON public.leave_requests FOR INSERT TO authenticated
  WITH CHECK (
    company_id = public.get_current_user_company_id()
    AND employee_id = auth.uid()::text
  );

CREATE POLICY "leave_requests_update_admin"
  ON public.leave_requests FOR UPDATE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
    )
  )
  WITH CHECK (company_id = public.get_current_user_company_id());

CREATE POLICY "leave_requests_delete"
  ON public.leave_requests FOR DELETE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      employee_id = auth.uid()::text
      OR (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
    )
  );

-- ── 3. alert_logs ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.alert_logs (
  id               TEXT PRIMARY KEY,
  company_id       TEXT NOT NULL,
  employee_id      TEXT,
  workstation_id   TEXT,
  alert_type       TEXT NOT NULL DEFAULT 'ABSENCE',
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  triggered_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledged     BOOLEAN NOT NULL DEFAULT FALSE
);

ALTER TABLE public.alert_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "alert_logs_select_company" ON public.alert_logs;
DROP POLICY IF EXISTS "alert_logs_insert"         ON public.alert_logs;
DROP POLICY IF EXISTS "alert_logs_update_admin"   ON public.alert_logs;

CREATE POLICY "alert_logs_select_company"
  ON public.alert_logs FOR SELECT TO authenticated
  USING (company_id = public.get_current_user_company_id());

CREATE POLICY "alert_logs_insert"
  ON public.alert_logs FOR INSERT TO authenticated
  WITH CHECK (company_id = public.get_current_user_company_id());

CREATE POLICY "alert_logs_update_admin"
  ON public.alert_logs FOR UPDATE TO authenticated
  USING (company_id = public.get_current_user_company_id())
  WITH CHECK (company_id = public.get_current_user_company_id());

-- ── 4. announcements ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.announcements (
  id         TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  author_id  TEXT NOT NULL DEFAULT '',
  title      TEXT NOT NULL DEFAULT '',
  content    TEXT NOT NULL DEFAULT '',
  priority   TEXT NOT NULL DEFAULT 'NORMAL',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "announcements_select_company" ON public.announcements;
DROP POLICY IF EXISTS "announcements_insert_admin"   ON public.announcements;
DROP POLICY IF EXISTS "announcements_update_admin"   ON public.announcements;
DROP POLICY IF EXISTS "announcements_delete_admin"   ON public.announcements;

CREATE POLICY "announcements_select_company"
  ON public.announcements FOR SELECT TO authenticated
  USING (company_id = public.get_current_user_company_id());

CREATE POLICY "announcements_insert_admin"
  ON public.announcements FOR INSERT TO authenticated
  WITH CHECK (
    company_id = public.get_current_user_company_id()
    AND (
      (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
    )
  );

CREATE POLICY "announcements_update_admin"
  ON public.announcements FOR UPDATE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
    )
  )
  WITH CHECK (company_id = public.get_current_user_company_id());

CREATE POLICY "announcements_delete_admin"
  ON public.announcements FOR DELETE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
    )
  );
