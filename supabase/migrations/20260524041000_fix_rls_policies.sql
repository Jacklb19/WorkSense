-- Migration: Recrear políticas RLS con filtrado por company_id
-- 1. Eliminar políticas existentes que permiten acceso total

-- daily_work_summaries
DROP POLICY IF EXISTS "daily_work_summaries_all_auth" ON public.daily_work_summaries;
DROP POLICY IF EXISTS "activity_rollups_all_auth" ON public.activity_rollups;
DROP POLICY IF EXISTS "employees_select_auth" ON public.employees;
DROP POLICY IF EXISTS "workstations_select_auth" ON public.workstations;
DROP POLICY IF EXISTS "shifts_select_auth" ON public.shifts;

-- 2. Asegurar RLS habilitado
ALTER TABLE public.daily_work_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_rollups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workstations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

-- 3. Función helper para obtener company_id del usuario (desde JWT o employees)
CREATE OR REPLACE FUNCTION public.get_current_user_company_id() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT COALESCE(
    (SELECT auth.jwt()->'company_id')::text,
    (SELECT company_id FROM public.employees WHERE id = auth.uid() LIMIT 1)
  );
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_current_user_company_id() TO authenticated;

-- 4. Política para employees - solo usuarios de la misma company pueden ver empleados
CREATE POLICY "employees_company_isolation"
  ON public.employees
  FOR SELECT
  TO authenticated
  USING (company_id = public.get_current_user_company_id());

-- 5. Política para workstations - solo workstations de la misma company
CREATE POLICY "workstations_company_isolation"
  ON public.workstations
  FOR ALL
  TO authenticated
  USING (company_id = public.get_current_user_company_id())
  WITH CHECK (company_id = public.get_current_user_company_id());

-- 6. Política para shifts - solo shifts de la misma company
CREATE POLICY "shifts_company_isolation"
  ON public.shifts
  FOR ALL
  TO authenticated
  USING (company_id = public.get_current_user_company_id())
  WITH CHECK (company_id = public.get_current_user_company_id());

-- 7. Política para daily_work_summaries - filtrado por company_id
CREATE POLICY "daily_work_summaries_company_isolation"
  ON public.daily_work_summaries
  FOR ALL
  TO authenticated
  USING (company_id = public.get_current_user_company_id())
  WITH CHECK (company_id = public.get_current_user_company_id());

-- 8. Política para activity_rollups - filtrado por company_id
CREATE POLICY "activity_rollups_company_isolation"
  ON public.activity_rollups
  FOR ALL
  TO authenticated
  USING (company_id = public.get_current_user_company_id())
  WITH CHECK (company_id = public.get_current_user_company_id());