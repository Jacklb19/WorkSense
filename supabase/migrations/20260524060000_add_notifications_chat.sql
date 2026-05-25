-- ================================================================
-- Migration: Notificaciones in-app + Chat admin↔empleado
-- ================================================================

-- ── 1. notifications ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id           TEXT PRIMARY KEY,
  company_id   TEXT NOT NULL,
  recipient_id TEXT,        -- NULL = basado en to_role
  to_role      TEXT,        -- 'ADMIN' | 'EMPLOYEE' | NULL (a un usuario específico)
  sender_id    TEXT,
  type         TEXT NOT NULL DEFAULT 'general',
  title        TEXT NOT NULL DEFAULT '',
  body         TEXT NOT NULL DEFAULT '',
  is_read      BOOLEAN NOT NULL DEFAULT FALSE,
  route        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;

-- Ver: mis notificaciones directas O las de mi rol en mi empresa
CREATE POLICY "notifications_select"
  ON public.notifications FOR SELECT TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      recipient_id = auth.uid()::text
      OR (
        to_role = 'ADMIN'
        AND (
          (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
          OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
        )
      )
    )
  );

-- Cualquier usuario autenticado de la empresa puede insertar notificaciones
CREATE POLICY "notifications_insert"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (company_id = public.get_current_user_company_id());

-- Solo el destinatario puede marcar como leída
CREATE POLICY "notifications_update"
  ON public.notifications FOR UPDATE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      recipient_id = auth.uid()::text
      OR (
        to_role = 'ADMIN'
        AND (
          (auth.jwt()->'app_metadata'->>'role')  IN ('ADMIN','SUPER_ADMIN')
          OR (auth.jwt()->'user_metadata'->>'role') IN ('ADMIN','SUPER_ADMIN')
        )
      )
    )
  )
  WITH CHECK (company_id = public.get_current_user_company_id());

-- ── 2. messages ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.messages (
  id           TEXT PRIMARY KEY,
  company_id   TEXT NOT NULL,
  sender_id    TEXT NOT NULL,
  recipient_id TEXT NOT NULL,
  content      TEXT NOT NULL DEFAULT '',
  is_read      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update" ON public.messages;

-- Ver mensajes donde soy sender o recipient
CREATE POLICY "messages_select"
  ON public.messages FOR SELECT TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND (
      sender_id    = auth.uid()::text
      OR recipient_id = auth.uid()::text
    )
  );

-- Cualquier autenticado de la empresa puede enviar
CREATE POLICY "messages_insert"
  ON public.messages FOR INSERT TO authenticated
  WITH CHECK (
    company_id = public.get_current_user_company_id()
    AND sender_id = auth.uid()::text
  );

-- Solo el destinatario puede marcar leído
CREATE POLICY "messages_update"
  ON public.messages FOR UPDATE TO authenticated
  USING (
    company_id = public.get_current_user_company_id()
    AND recipient_id = auth.uid()::text
  )
  WITH CHECK (company_id = public.get_current_user_company_id());
