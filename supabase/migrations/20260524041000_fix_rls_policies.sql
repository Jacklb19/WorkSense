-- Migration: Recrear políticas RLS limpias para tablas nuevas y employees
-- 1. Eliminar políticas existentes que puedan estar en conflicto

-- daily_work_summaries
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.daily_work_summaries;
DROP POLICY IF EXISTS "Allow select for own company" ON public.daily_work_summaries;
DROP POLICY IF EXISTS "Allow update for own company" ON public.daily_work_summaries;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.daily_work_summaries;

-- activity_rollups
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.activity_rollups;
DROP POLICY IF EXISTS "Allow select for own company" ON public.activity_rollups;
DROP POLICY IF EXISTS "Allow update for own company" ON public.activity_rollups;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON public.activity_rollups;

-- 2. Asegurar RLS habilitado
ALTER TABLE public.daily_work_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_rollups ENABLE ROW LEVEL SECURITY;

-- 3. Políticas para daily_work_summaries
CREATE POLICY "daily_work_summaries_all_auth"
  ON public.daily_work_summaries
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 4. Políticas para activity_rollups
CREATE POLICY "activity_rollups_all_auth"
  ON public.activity_rollups
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- 5. Asegurar que employees también tenga política SELECT para authenticated
-- (currentUserProvider y fetchCurrentEmployee dependen de esto)
CREATE POLICY IF NOT EXISTS "employees_select_auth"
  ON public.employees
  FOR SELECT
  TO authenticated
  USING (true);

-- 6. Política SELECT para workstations (sync pull)
CREATE POLICY IF NOT EXISTS "workstations_select_auth"
  ON public.workstations
  FOR SELECT
  TO authenticated
  USING (true);

-- 7. Política SELECT para shifts
CREATE POLICY IF NOT EXISTS "shifts_select_auth"
  ON public.shifts
  FOR SELECT
  TO authenticated
  USING (true);