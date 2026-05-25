-- ================================================================
-- Migration: Tabla de tokens FCM para notificaciones push reales
-- ================================================================

CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  user_id     TEXT PRIMARY KEY,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'android',   -- 'android' | 'ios'
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "fcm_tokens_select" ON public.fcm_tokens;
DROP POLICY IF EXISTS "fcm_tokens_upsert" ON public.fcm_tokens;
DROP POLICY IF EXISTS "fcm_tokens_delete" ON public.fcm_tokens;

-- Solo el propio usuario puede leer/escribir/eliminar su token
CREATE POLICY "fcm_tokens_select"
  ON public.fcm_tokens FOR SELECT TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "fcm_tokens_upsert"
  ON public.fcm_tokens FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "fcm_tokens_update"
  ON public.fcm_tokens FOR UPDATE TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "fcm_tokens_delete"
  ON public.fcm_tokens FOR DELETE TO authenticated
  USING (user_id = auth.uid()::text);

-- La Edge Function send-push necesita leer tokens de OTROS usuarios
-- (el admin lee el token del empleado y viceversa).
-- Esto lo manejamos con el service_role key en la Edge Function
-- (las Edge Functions con service_role bypasean RLS).
