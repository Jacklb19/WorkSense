import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim()
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`)
  }

  return value
}

function normalizeRole(rawRole: unknown): string {
  const normalized = rawRole?.toString().trim().toUpperCase()
  switch (normalized) {
    case 'SUPER_ADMIN':
    case 'ADMIN':
    case 'EMPLOYEE':
    case 'CAMERA_MONITOR':
      return normalized
    default:
      throw new Error('Invalid role value')
  }
}

function getCanonicalRole(user: { app_metadata?: Record<string, unknown>; user_metadata?: Record<string, unknown> }): string {
  return normalizeRole(
    user.app_metadata?.role ?? user.user_metadata?.role ?? 'EMPLOYEE',
  )
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = requireEnv('SUPABASE_URL')
    const supabaseAnonKey = requireEnv('SUPABASE_ANON_KEY')
    const supabaseServiceKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY')

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: userError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', ''),
    )

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid user token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const callerRole = getCanonicalRole(user)
    if (callerRole !== 'ADMIN' && callerRole !== 'SUPER_ADMIN') {
      return new Response(JSON.stringify({ error: 'Unauthorized. Admin role required.' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const adminSupabase = createClient(supabaseUrl, supabaseServiceKey)
    const {
      email,
      password,
      name,
      lastName,
      role,
      companyId,
      shiftId,
    } = await req.json()

    if (!email || !password || !name || !lastName || !role || !companyId) {
      return new Response(JSON.stringify({ error: 'Missing required parameters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const canonicalRole = normalizeRole(role)
    const metadata = { role: canonicalRole, company_id: companyId }

    const { data: authData, error: authError } = await adminSupabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: metadata,
      app_metadata: metadata,
    })

    if (authError || !authData.user) {
      return new Response(JSON.stringify({ error: authError?.message || 'Error creating auth user' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const newUserId = authData.user.id

    const employeePayload = {
      id: newUserId,
      name,
      last_name: lastName,
      role: canonicalRole,
      email,
      company_id: companyId,
      shift_id: shiftId ?? null,
    }

    const { error: dbError } = await adminSupabase.from('employees').insert(employeePayload)

    if (dbError) {
      await adminSupabase.auth.admin.deleteUser(newUserId)
      return new Response(JSON.stringify({ error: `DB Error: ${dbError.message}` }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({
      id: newUserId,
      employee: employeePayload,
      message: 'Employee created successfully',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
