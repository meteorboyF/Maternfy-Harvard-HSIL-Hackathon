import { NextResponse } from 'next/server'
import Anthropic from '@anthropic-ai/sdk'
import { createClient } from '@supabase/supabase-js'

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!   // server-only key
)

export async function GET(
  _request: Request,
  { params }: { params: { id: string } }
) {
  const { id } = params

  // Fetch patient data
  const [patientRes, vitalsRes, triageRes] = await Promise.all([
    supabase.from('patients').select('*').eq('id', id).single(),
    supabase
      .from('vitals_logs')
      .select('*')
      .eq('patient_id', id)
      .order('logged_at', { ascending: false })
      .limit(7),
    supabase
      .from('triage_events')
      .select('triage_tier, advice_english, created_at')
      .eq('patient_id', id)
      .order('created_at', { ascending: false })
      .limit(3),
  ])

  if (!patientRes.data) {
    return NextResponse.json({ error: 'Patient not found' }, { status: 404 })
  }

  const p = patientRes.data
  const vitals = vitalsRes.data ?? []
  const triage = triageRes.data ?? []

  const latestBp = vitals[0] ? `${vitals[0].systolic_bp}/${vitals[0].diastolic_bp} mmHg` : 'N/A'
  const tierCounts = triage.reduce((acc: Record<string, number>, t) => {
    acc[t.triage_tier] = (acc[t.triage_tier] ?? 0) + 1
    return acc
  }, {})

  const prompt = `Generate a concise 3-sentence clinical summary for a provider reviewing this patient:

Patient: ${p.name}, Age ${p.age}, ${p.weeks_gestation} weeks gestation, G${p.gravida}P${p.parity}, Blood type ${p.blood_type}
Latest BP: ${latestBp}
Recent triage: ${JSON.stringify(tierCounts)} (last ${triage.length} events)
Vitals trend (last 7 days BP): ${vitals.map((v: any) => `${v.systolic_bp}/${v.diastolic_bp}`).join(', ')}

Write for a busy OB provider. Flag any red flags. Do not diagnose or prescribe. 3 sentences maximum.`

  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 200,
    messages: [{ role: 'user', content: prompt }],
  })

  const summary = (message.content[0] as { text: string }).text.trim()
  return NextResponse.json({ summary })
}
