-- Migration: Remove foreign key constraints on computed tables
-- The app controls data consistency; FK violations block sync of stale test data

ALTER TABLE public.daily_work_summaries
  DROP CONSTRAINT IF EXISTS daily_work_summaries_employee_id_fkey,
  DROP CONSTRAINT IF EXISTS daily_work_summaries_company_id_fkey,
  DROP CONSTRAINT IF EXISTS daily_work_summaries_shift_id_fkey;

ALTER TABLE public.activity_rollups
  DROP CONSTRAINT IF EXISTS activity_rollups_employee_id_fkey,
  DROP CONSTRAINT IF EXISTS activity_rollups_company_id_fkey,
  DROP CONSTRAINT IF EXISTS activity_rollups_workstation_id_fkey;