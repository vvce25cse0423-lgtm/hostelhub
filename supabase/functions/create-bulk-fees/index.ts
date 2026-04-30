// supabase/functions/create-bulk-fees/index.ts
// Admin edge function to create monthly fees for all students
// Deploy with: supabase functions deploy create-bulk-fees
// Call via: POST /functions/v1/create-bulk-fees (admin auth required)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Verify caller is admin
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: corsHeaders
      })
    }

    const { data: profile } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!profile || !['admin', 'warden'].includes(profile.role)) {
      return new Response(JSON.stringify({ error: 'Forbidden: Admins only' }), {
        status: 403, headers: corsHeaders
      })
    }

    const { month, amount, fee_type, due_date } = await req.json()

    if (!month || !amount || !fee_type || !due_date) {
      return new Response(
        JSON.stringify({ error: 'month, amount, fee_type, and due_date required' }),
        { status: 400, headers: corsHeaders }
      )
    }

    // Get all active students
    const { data: students, error: studentsError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('role', 'student')

    if (studentsError) throw studentsError

    // Create fee records for each student
    const feeRecords = students.map((s: { id: string }) => ({
      student_id: s.id,
      amount,
      fee_type,
      month,
      due_date,
      status: 'pending',
    }))

    const { data, error } = await supabaseAdmin
      .from('fees')
      .insert(feeRecords)
      .select()

    if (error) throw error

    // Send notification to each student
    for (const student of students) {
      await supabaseAdmin.from('notifications').insert({
        user_id: student.id,
        title: '💳 Fee Reminder',
        body: `Your ${fee_type} fee of ₹${amount} for ${month} is due on ${due_date}`,
        type: 'fee_reminder',
        data: { month, amount, fee_type },
      })
    }

    return new Response(
      JSON.stringify({
        success: true,
        created: data?.length ?? 0,
        message: `Created ${feeRecords.length} fee records for ${month}`,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
