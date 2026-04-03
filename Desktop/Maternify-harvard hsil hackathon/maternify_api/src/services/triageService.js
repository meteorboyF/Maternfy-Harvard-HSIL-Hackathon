/**
 * Maternify Triage Service — F5
 * Fetches patient vitals from Supabase → builds Claude system prompt →
 * calls claude-sonnet-4-6 → parses JSON response → persists triage event →
 * if Red: fires Firestore alert pipeline (F8 hook point).
 */

const Anthropic = require('@anthropic-ai/sdk')
const supabase = require('../config/supabase')
const { db: firestore } = require('../config/firebase')

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

const SYSTEM_PROMPT = `You are the AI triage engine for Maternify, a maternal health platform for Bangladesh.
The patient's recent vitals: {{vitals_json}}
Gestational week or postpartum day: {{week_or_day}}
Current ML risk tier: {{risk_tier}}

Classify the symptom input and respond ONLY with valid JSON (no markdown, no explanation):
{
  "triage_tier": "green|yellow|red",
  "advice_bangla": "...",
  "advice_english": "...",
  "escalation_required": true|false,
  "suggested_action": "..."
}

Rules:
- Never diagnose. Never name specific medications.
- Yellow/Red always recommend contacting provider.
- Red responses must include emergency left-lateral positioning instructions.
- Bangla responses must be Grade 6 reading level (simple, short sentences).
- advice_bangla must be in Bengali Unicode script, not transliteration.`

/**
 * Run the full triage pipeline for a patient.
 *
 * @param {string} patientId
 * @param {string} inputText   - symptom text (Bangla or English)
 * @param {string} inputLang   - 'bn' | 'en'
 * @param {string} mlRiskTier  - from XGBoost service (green|yellow|red)
 * @returns {object} persisted triage_event row
 */
async function runTriage(patientId, inputText, inputLang, mlRiskTier = 'green') {
  // 1. Fetch patient + last 7 days of vitals
  const [patientRes, vitalsRes] = await Promise.all([
    supabase.from('patients').select('*').eq('id', patientId).single(),
    supabase
      .from('vitals_logs')
      .select('*')
      .eq('patient_id', patientId)
      .gte('logged_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .order('logged_at', { ascending: false })
      .limit(14),
  ])

  if (patientRes.error) throw new Error(`Patient not found: ${patientRes.error.message}`)
  const patient = patientRes.data
  const vitals = vitalsRes.data || []

  // 2. Build vitals summary for prompt
  const vitalsSummary = vitals.slice(0, 3).map((v) => ({
    date: v.logged_at.slice(0, 10),
    bp: `${v.systolic_bp}/${v.diastolic_bp}`,
    weight_kg: v.weight_kg,
    glucose: v.blood_glucose,
    kicks: v.kick_count,
  }))

  const weekOrDay = `${patient.weeks_gestation} weeks gestation`

  // 3. Build system prompt
  const systemPrompt = SYSTEM_PROMPT
    .replace('{{vitals_json}}', JSON.stringify(vitalsSummary))
    .replace('{{week_or_day}}', weekOrDay)
    .replace('{{risk_tier}}', mlRiskTier)

  // 4. Call Claude API
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 512,
    system: systemPrompt,
    messages: [{ role: 'user', content: inputText }],
  })

  // 5. Parse JSON response
  const rawContent = message.content[0].text.trim()
  let parsed
  try {
    // Strip any accidental markdown fences
    const jsonStr = rawContent.replace(/^```json?\s*/i, '').replace(/```\s*$/i, '').trim()
    parsed = JSON.parse(jsonStr)
  } catch {
    throw new Error(`Claude returned non-JSON: ${rawContent.slice(0, 200)}`)
  }

  const { triage_tier, advice_bangla, advice_english, escalation_required, suggested_action } = parsed

  // Validate tier
  if (!['green', 'yellow', 'red'].includes(triage_tier)) {
    throw new Error(`Invalid triage_tier from Claude: ${triage_tier}`)
  }

  // 6. Persist to Supabase
  const { data: triageEvent, error: insertErr } = await supabase
    .from('triage_events')
    .insert({
      patient_id: patientId,
      input_text: inputText,
      input_lang: inputLang,
      triage_tier,
      advice_bangla,
      advice_english,
      escalation_required: !!escalation_required,
      suggested_action: suggested_action || '',
    })
    .select()
    .single()

  if (insertErr) throw new Error(`Failed to persist triage event: ${insertErr.message}`)

  // 7. Red alert pipeline — write to Firestore + Supabase alerts (F8 hook)
  if (triage_tier === 'red') {
    await Promise.all([
      _writeFirestoreAlert(patient, triageEvent),
      _writeSupabaseAlert(patient, triageEvent),
    ])
  }

  return triageEvent
}

// ── Alert helpers ────────────────────────────────────────────────────────────

async function _writeFirestoreAlert(patient, triageEvent) {
  try {
    await firestore.collection('alerts').add({
      patient_id: patient.id,
      patient_name: patient.name,
      provider_id: patient.provider_id,
      triage_event_id: triageEvent.id,
      triage_tier: 'red',
      message: triageEvent.advice_english,
      suggested_action: triageEvent.suggested_action,
      weeks_gestation: patient.weeks_gestation,
      blood_type: patient.blood_type,
      read: false,
      created_at: new Date().toISOString(),
    })
  } catch (err) {
    // Non-fatal — log but don't crash the triage response
    console.error('Firestore alert write failed:', err.message)
  }
}

async function _writeSupabaseAlert(patient, triageEvent) {
  await supabase.from('alerts').insert({
    patient_id: patient.id,
    provider_id: patient.provider_id,
    alert_type: 'red_triage',
    message: `RED: ${patient.name} (${patient.weeks_gestation}w) — ${triageEvent.suggested_action || triageEvent.advice_english.slice(0, 120)}`,
    read: false,
  })
}

module.exports = { runTriage }
