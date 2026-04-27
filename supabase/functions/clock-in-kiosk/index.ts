import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Configurar CORS
  const headers = { 'Access-Control-Allow-Origin': '*', 'Content-Type': 'application/json' }
  if (req.method === 'OPTIONS') return new Response('ok', { headers })

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { employeeId, workstationId } = await req.json()

    // 1. Verificar sesión abierta
    const { data: openSession } = await supabase
      .from('attendance_logs')
      .select('id')
      .eq('employee_id', employeeId)
      .is('clock_out_time', null)
      .maybeSingle()

    if (openSession) {
      // Tiene sesión -> CLOCK OUT y apagar estación
      await supabase.from('attendance_logs').update({ clock_out_time: new Date().toISOString() }).eq('id', openSession.id)
      await supabase.from('workstations').update({ status: 'IDLE' }).eq('assigned_employee_id', employeeId)
      return new Response(JSON.stringify({ action: 'CLOCK_OUT' }), { headers })
    } else {
      // No tiene sesión -> CLOCK IN y prender estación
      await supabase.from('attendance_logs').insert([{ 
        employee_id: employeeId, 
        workstation_id: workstationId,
        shift_date: new Date().toISOString().split('T')[0],
        clock_in_time: new Date().toISOString() 
      }])
      await supabase.from('workstations').update({ status: 'ACTIVE', last_employee_id: employeeId }).eq('assigned_employee_id', employeeId)
      return new Response(JSON.stringify({ action: 'CLOCK_IN' }), { headers })
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { headers, status: 400 })
  }
})
