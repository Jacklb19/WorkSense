-- =====================================================================
-- Fix evaluations RLS — add explicit WITH CHECK on write policy.
--
-- The original "evaluations_write_admin" policy used only USING.
-- PostgreSQL technically reuses USING as WITH CHECK for INSERT/UPDATE,
-- but some Supabase versions enforce WITH CHECK explicitly for INSERT.
-- This migration drops and recreates both policies cleanly.
-- =====================================================================

-- Drop old policies (idempotent — no-op if they don't exist)
drop policy if exists "evaluations_write_admin"  on public.evaluations;
drop policy if exists "evaluations_read_company" on public.evaluations;

-- ── SELECT — all users of the same company can read ──────────────────
create policy "evaluations_read_company" on public.evaluations
  for select
  using (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
  );

-- ── ALL (INSERT / UPDATE / DELETE) — admins only ─────────────────────
-- Both USING (row-level filter) and WITH CHECK (new-row validation)
-- are specified explicitly so there is no ambiguity.
create policy "evaluations_write_admin" on public.evaluations
  for all
  using (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
    and (
      select role from public.employees where id = auth.uid()
    ) in ('admin', 'super_admin')
  )
  with check (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
    and (
      select role from public.employees where id = auth.uid()
    ) in ('admin', 'super_admin')
  );
