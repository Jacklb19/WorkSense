-- Migration: RLS policies for tasks and leave_requests tables
-- Fixes: assigned tasks not appearing on employee devices due to missing RLS policies

-- ── tasks ─────────────────────────────────────────────────────────────────────

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Drop any old blanket policies
DROP POLICY IF EXISTS "tasks_all_auth" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_auth" ON public.tasks;

-- Employees can read tasks assigned to them OR all tasks of their company (for admin)
CREATE POLICY "tasks_select_company"
  ON public.tasks
  FOR SELECT
  TO authenticated
  USING (company_id = public.get_current_user_company_id());

-- Only admins/superadmins can create tasks
CREATE POLICY "tasks_insert_admin"
  ON public.tasks
  FOR INSERT
  TO authenticated
  WITH CHECK (company_id = public.get_current_user_company_id());

-- Admins can update any task; employees can only update their own tasks (status change)
CREATE POLICY "tasks_update"
  ON public.tasks
  FOR UPDATE
  TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      -- Employee can update only tasks assigned to them (e.g., change status)
      assigned_to_id = auth.uid()
      OR
      -- Admin/superadmin can update any task in their company
      (auth.jwt()->'app_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
      OR
      (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
    )
  )
  WITH CHECK (company_id = public.get_current_user_company_id());

-- Only admins can delete tasks
CREATE POLICY "tasks_delete_admin"
  ON public.tasks
  FOR DELETE
  TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      (auth.jwt()->'app_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
      OR
      (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
    )
  );

-- ── leave_requests ────────────────────────────────────────────────────────────

ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "leave_requests_all_auth" ON public.leave_requests;
DROP POLICY IF EXISTS "leave_requests_select_auth" ON public.leave_requests;

-- All authenticated users of the same company can read leave requests
CREATE POLICY "leave_requests_select_company"
  ON public.leave_requests
  FOR SELECT
  TO authenticated
  USING (company_id = public.get_current_user_company_id());

-- Any employee can create a leave request for themselves
CREATE POLICY "leave_requests_insert_self"
  ON public.leave_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (
    company_id = public.get_current_user_company_id()
    AND employee_id = auth.uid()
  );

-- Employees can delete their own pending requests; admins can delete any
CREATE POLICY "leave_requests_delete"
  ON public.leave_requests
  FOR DELETE
  TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      employee_id = auth.uid()
      OR (auth.jwt()->'app_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
    )
  );

-- Admins can update leave requests (approve/reject); employees cannot
CREATE POLICY "leave_requests_update_admin"
  ON public.leave_requests
  FOR UPDATE
  TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      (auth.jwt()->'app_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
      OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN', 'SUPER_ADMIN')
    )
  )
  WITH CHECK (company_id = public.get_current_user_company_id());
