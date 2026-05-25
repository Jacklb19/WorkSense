-- =====================================================================
-- NÓMINA BÁSICA — payroll_configs, payroll_periods, payroll_entries
-- =====================================================================

-- ── payroll_configs ────────────────────────────────────────────────────────────
create table if not exists public.payroll_configs (
  id           text primary key,
  employee_id  uuid not null references public.employees(id) on delete cascade,
  company_id   uuid not null,
  hourly_rate  numeric(12, 2) not null default 0,
  currency     text not null default 'COP',
  updated_at   timestamptz not null default now()
);

create index if not exists idx_payroll_configs_company
  on public.payroll_configs (company_id);

-- ── payroll_periods ────────────────────────────────────────────────────────────
create table if not exists public.payroll_periods (
  id             text primary key,
  company_id     uuid not null,
  name           text not null,
  start_date     date not null,
  end_date       date not null,
  status         text not null default 'draft'
                   check (status in ('draft', 'approved', 'paid')),
  total_gross    numeric(14, 2) not null default 0,
  employee_count int not null default 0,
  created_at     timestamptz not null default now(),
  created_by     uuid
);

create index if not exists idx_payroll_periods_company
  on public.payroll_periods (company_id, created_at desc);

-- ── payroll_entries ────────────────────────────────────────────────────────────
create table if not exists public.payroll_entries (
  id           text primary key,
  period_id    text not null references public.payroll_periods(id) on delete cascade,
  employee_id  uuid not null references public.employees(id) on delete cascade,
  company_id   uuid not null,
  hours_worked numeric(8, 2) not null default 0,
  hourly_rate  numeric(12, 2) not null default 0,
  gross_pay    numeric(14, 2) not null default 0,
  deductions   numeric(14, 2) not null default 0,
  net_pay      numeric(14, 2) not null default 0,
  currency     text not null default 'COP'
);

create index if not exists idx_payroll_entries_period
  on public.payroll_entries (period_id);

create index if not exists idx_payroll_entries_employee
  on public.payroll_entries (employee_id);

-- ── RLS ────────────────────────────────────────────────────────────────────────
alter table public.payroll_configs   enable row level security;
alter table public.payroll_periods   enable row level security;
alter table public.payroll_entries   enable row level security;

-- Admins de la misma empresa pueden leer/escribir todo
create policy "payroll_configs_company_access" on public.payroll_configs
  using (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
  );

create policy "payroll_periods_company_access" on public.payroll_periods
  using (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
  );

create policy "payroll_entries_company_access" on public.payroll_entries
  using (
    company_id = (
      select company_id from public.employees where id = auth.uid()
    )
  );
