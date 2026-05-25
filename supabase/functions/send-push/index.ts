import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { encodeBase64Url } from "https://deno.land/std@0.208.0/encoding/base64url.ts";

// ── Tipos ─────────────────────────────────────────────────────────────────────

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface PushPayload {
  recipient_id?: string;   // Para un usuario específico
  to_role?: string;        // 'ADMIN' para todos los admins de la empresa
  company_id?: string;     // Requerido si to_role está presente
  title: string;
  body: string;
  data?: Record<string, string>;
}

// ── JWT / OAuth2 para FCM HTTP v1 API ────────────────────────────────────────

async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: object): string =>
    encodeBase64Url(new TextEncoder().encode(JSON.stringify(obj)));

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Limpiar el PEM y convertir a ArrayBuffer
  const pemBody = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${encodeBase64Url(new Uint8Array(signature))}`;

  // Intercambiar JWT por access_token de Google OAuth2
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    throw new Error(`Error obteniendo access_token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token as string;
}

// ── Enviar un mensaje FCM a un token ─────────────────────────────────────────

async function sendFcmMessage(
  projectId: string,
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: {
            priority: "high",
            notification: {
              channel_id: "worksense_push",
              sound: "default",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        },
      }),
    }
  );

  if (!res.ok) {
    const err = await res.text();
    console.error(`[FCM] Error enviando a token ${fcmToken.substring(0, 20)}…: ${err}`);
    return false;
  }
  return true;
}

// ── Handler principal ─────────────────────────────────────────────────────────

serve(async (req: Request) => {
  // Permitir CORS para llamadas desde la app
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const payload: PushPayload = await req.json();
    const { recipient_id, to_role, company_id, title, body, data = {} } = payload;

    if (!title || !body) {
      return new Response(JSON.stringify({ error: "title y body son requeridos" }), {
        status: 400,
      });
    }

    // 1. Obtener credenciales
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT no configurado" }),
        { status: 500 }
      );
    }
    const sa: ServiceAccount = JSON.parse(serviceAccountJson);

    // 2. Supabase admin client (service_role bypasea RLS para leer tokens)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // 3. Obtener FCM tokens de los destinatarios
    let tokens: string[] = [];

    if (recipient_id) {
      // Notificación para un usuario específico
      const { data: row } = await adminClient
        .from("fcm_tokens")
        .select("token")
        .eq("user_id", recipient_id)
        .maybeSingle();

      if (row?.token) tokens.push(row.token);
    } else if (to_role === "ADMIN" && company_id) {
      // Notificación para todos los admins de una empresa
      const { data: admins } = await adminClient
        .from("employees")
        .select("id")
        .eq("company_id", company_id)
        .in("role", ["ADMIN", "SUPER_ADMIN"]);

      if (admins && admins.length > 0) {
        const adminIds = admins.map((a: { id: string }) => a.id);
        const { data: tokenRows } = await adminClient
          .from("fcm_tokens")
          .select("token")
          .in("user_id", adminIds);

        tokens = tokenRows?.map((r: { token: string }) => r.token) ?? [];
      }
    }

    if (tokens.length === 0) {
      console.log("[FCM] Sin tokens para enviar");
      return new Response(JSON.stringify({ sent: 0, message: "sin tokens" }), {
        status: 200,
      });
    }

    // 4. Obtener access token de Google OAuth2
    const accessToken = await getFcmAccessToken(sa);

    // 5. Enviar a cada token
    let sent = 0;
    for (const token of tokens) {
      const ok = await sendFcmMessage(
        sa.project_id,
        accessToken,
        token,
        title,
        body,
        data
      );
      if (ok) sent++;
    }

    console.log(`[FCM] Enviados ${sent}/${tokens.length} pushes`);
    return new Response(JSON.stringify({ sent, total: tokens.length }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("[FCM] Error en Edge Function:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
