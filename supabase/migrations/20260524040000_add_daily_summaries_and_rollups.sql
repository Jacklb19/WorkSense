-- Migration: Create daily_work_summaries and activity_rollups tables
-- These tables correspond to local payloads built by WorktimeReconciler

CREATE TABLE IF NOT EXISTS public.daily_work_summaries (
  id text NOT NULL,
  employee_id uuid NOT NULL,
  company_id uuid NOT NULL,
  work_date text NOT NULL,
  shift_id uuid,
  expected_minutes integer NOT NULL DEFAULT 0,
  worked_minutes integer NOT NULL DEFAULT 0,
  break_minutes integer NOT NULL DEFAULT 0,
  absence_minutes integer NOT NULL DEFAULT 0,
  late_minutes integer NOT NULL DEFAULT 0,
  extra_minutes integer NOT NULL DEFAULT 0,
  session_count integer NOT NULL DEFAULT 0,
  anomalies_json text NOT NULL DEFAULT '[]'::text,
  source_version integer NOT NULL DEFAULT 1,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT daily_work_summaries_pkey PRIMARY KEY (id),
  CONSTRAINT daily_work_summaries_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id),
  CONSTRAINT daily_work_summaries_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id),
  CONSTRAINT daily_work_summaries_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shifts(id)
);

-- Enable RLS and add policies for daily_work_summaries
ALTER TABLE public.daily_work_summaries ENABLE ROW LEVEL SECURITY;

-- Permitir todas las operaciones a usuarios autenticados (app es cliente confiable)
CREATE POLICY "Allow all for authenticated users"
  ON public.daily_work_summaries
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE TABLE IF NOT EXISTS public.activity_rollups (
  id text NOT NULL,
  employee_id uuid NOT NULL,
  company_id uuid NOT NULL,
  workstation_id uuid NOT NULL,
  window_start timestamp with time zone NOT NULL,
  window_end timestamp with time zone NOT NULL,
  working_minutes integer NOT NULL DEFAULT 0,
  distracted_minutes integer NOT NULL DEFAULT 0,
  absent_minutes integer NOT NULL DEFAULT 0,
  unknown_minutes integer NOT NULL DEFAULT 0,
  avg_confidence double precision NOT NULL DEFAULT 0.0,
  event_count integer NOT NULL DEFAULT 0,
  CONSTRAINT activity_rollups_pkey PRIMARY KEY (id),
  CONSTRAINT activity_rollups_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id),
  CONSTRAINT activity_rollups_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id),
  CONSTRAINT activity_rollups_workstation_id_fkey FOREIGN KEY (workstation_id) REFERENCES public.workstations(id)
);

-- Enable RLS and add policies for activity_rollups
ALTER TABLE public.activity_rollups ENABLE ROW LEVEL SECURITY;

-- Permitir todas las operaciones a usuarios autenticados (app es cliente confiable)
CREATE POLICY "Allow all for authenticated users"
  ON public.activity_rollups
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
