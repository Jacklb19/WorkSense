-- =====================================================================
-- EVALUACIONES DE DESEMPEÑO — evaluations
-- =====================================================================

create table if not exists public.evaluations (
  id           text primary key,
  company_id   uuid not null,
  employee_id  uuid not null references public.employees(id) on delete cascade,
  reviewer_id  uuid,
  period       text not null,                     -- "Enero 2026", "Q1 2026", etc.
  criteria     jsonb not null default '[]',       -- [{name, max_score}, ...]
  scores       jsonb not null default '{}',       -- {criterionName: score, ...}
  total_score  numeric(8, 2) not null default 0,
  max_score    numeric(8, 2) not null default 0,
  notes        text,
  created_at   timestamptz not null default now()
);

create index if not exists idx_evaluations_company
  on public.evaluations (company_id, created_at desc);

create index if not exists idx_evaluations_employee
  on public.evaluations (employee_id, created_at desc);

-- ── RLS ────────────────────────────────────────────────────────────────────────
alter table public.evaluations enable row level security;

-- Todos los usuarios de la empresa pueden leer evaluaciones de su empresa.
-- Solo admins (rol != 'employee') pueden insertar/actualizar/borrar.
create policy "evaluations_read_company" on public.evaluations
  for select
  using (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
  );

create policy "evaluations_write_admin" on public.evaluations
  for all
  using (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
    and (
      select role from public.employees where id = auth.uid()
    ) in ('admin', 'super_admin')
  );
