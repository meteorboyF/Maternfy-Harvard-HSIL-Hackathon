/**
 * Maternify Seed Script — F4
 * Creates 5 synthetic demo patients with 14 days of vitals history.
 * Patients 4 and 5 have preeclampsia-risk trajectories.
 *
 * Usage: node src/db/seed.js
 * Requires: SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY in .env
 */

require('dotenv').config()
const { createClient } = require('@supabase/supabase-js')
const { v4: uuid } = require('uuid')

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

const PROVIDER_ID = 'demo-provider-uid-001'

// ── Patient definitions ─────────────────────────────────────────────────────
const PATIENTS = [
  {
    id: uuid(),
    name: 'Fatema Begum',
    age: 26,
    phone: '01711000001',
    gravida: 2,
    parity: 1,
    weeks_gestation: 28,
    blood_type: 'B+',
    provider_id: PROVIDER_ID,
    profile: 'normal',
  },
  {
    id: uuid(),
    name: 'Rahela Khatun',
    age: 31,
    phone: '01711000002',
    gravida: 1,
    parity: 0,
    weeks_gestation: 34,
    blood_type: 'O+',
    provider_id: PROVIDER_ID,
    profile: 'normal',
  },
  {
    id: uuid(),
    name: 'Nasrin Akter',
    age: 22,
    phone: '01711000003',
    gravida: 1,
    parity: 0,
    weeks_gestation: 20,
    blood_type: 'A+',
    provider_id: PROVIDER_ID,
    profile: 'normal',
  },
  {
    id: uuid(),
    name: 'Shirin Sultana',    // ← preeclampsia-risk trajectory
    age: 35,
    phone: '01711000004',
    gravida: 3,
    parity: 2,
    weeks_gestation: 36,
    blood_type: 'AB+',
    provider_id: PROVIDER_ID,
    profile: 'preeclampsia_risk',
  },
  {
    id: uuid(),
    name: 'Mina Parvin',       // ← preeclampsia-risk trajectory
    age: 29,
    phone: '01711000005',
    gravida: 2,
    parity: 1,
    weeks_gestation: 32,
    blood_type: 'O-',
    provider_id: PROVIDER_ID,
    profile: 'preeclampsia_risk',
  },
]

// ── Vitals generator ─────────────────────────────────────────────────────────
function generateVitals(patient, daysAgo) {
  const isRisk = patient.profile === 'preeclampsia_risk'
  const riskFactor = isRisk ? (14 - daysAgo) / 14 : 0  // escalates toward today

  const baseSystolic = isRisk ? 125 + Math.round(riskFactor * 35) : 110 + Math.round(Math.random() * 10)
  const baseDiastolic = isRisk ? 82 + Math.round(riskFactor * 22) : 72 + Math.round(Math.random() * 8)

  return {
    id: uuid(),
    patient_id: patient.id,
    systolic_bp: baseSystolic + Math.round((Math.random() - 0.5) * 6),
    diastolic_bp: baseDiastolic + Math.round((Math.random() - 0.5) * 4),
    weight_kg: parseFloat((55 + patient.weeks_gestation * 0.3 + (Math.random() - 0.5)).toFixed(1)),
    blood_glucose: parseFloat((isRisk ? 6.5 + riskFactor * 1.5 : 5.0 + Math.random() * 0.8).toFixed(1)),
    kick_count: isRisk && daysAgo < 3 ? Math.floor(5 + Math.random() * 5) : Math.floor(10 + Math.random() * 10),
    logged_at: new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000).toISOString(),
  }
}

// ── Triage seed events ───────────────────────────────────────────────────────
function triageEvents(patient) {
  const isRisk = patient.profile === 'preeclampsia_risk'
  if (!isRisk) return []

  return [
    {
      id: uuid(),
      patient_id: patient.id,
      input_text: 'মাথা ঘুরছে, চোখে ঝাপসা দেখছি, পা ফুলে গেছে',
      input_lang: 'bn',
      triage_tier: 'red',
      advice_bangla:
        'আপনার লক্ষণগুলো গুরুতর। এখনই বাম দিকে শুয়ে পড়ুন এবং নিকটতম হাসপাতালে যান। আপনার ডাক্তারকে এখনই ফোন করুন।',
      advice_english:
        'Your symptoms are serious. Lie on your left side immediately and go to the nearest hospital. Call your doctor right now.',
      escalation_required: true,
      suggested_action: 'Emergency hospital visit — possible preeclampsia',
      created_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
    },
  ]
}

// ── Alerts seed ──────────────────────────────────────────────────────────────
function alertsForPatient(patient) {
  const isRisk = patient.profile === 'preeclampsia_risk'
  if (!isRisk) return []

  return [
    {
      id: uuid(),
      patient_id: patient.id,
      provider_id: PROVIDER_ID,
      alert_type: 'red_triage',
      message: `${patient.name} (${patient.weeks_gestation}w): Red triage — headache, blurred vision, oedema. Immediate review required.`,
      read: false,
      created_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: uuid(),
      patient_id: patient.id,
      provider_id: PROVIDER_ID,
      alert_type: 'bp_critical',
      message: `${patient.name}: BP ${patient.profile === 'preeclampsia_risk' ? '158/104' : ''} mmHg — above critical threshold.`,
      read: false,
      created_at: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(),
    },
  ]
}

// ── Main seed function ───────────────────────────────────────────────────────
async function seed() {
  console.log('🌱 Seeding Maternify demo data...\n')

  // 1. Insert patients
  const patientRows = PATIENTS.map(({ profile, ...p }) => p)
  const { error: pErr } = await supabase.from('patients').upsert(patientRows)
  if (pErr) { console.error('patients error:', pErr.message); process.exit(1) }
  console.log(`✅ Inserted ${PATIENTS.length} patients`)

  // 2. Insert 14 days of vitals per patient
  const allVitals = []
  for (const patient of PATIENTS) {
    for (let day = 13; day >= 0; day--) {
      allVitals.push(generateVitals(patient, day))
    }
  }
  const { error: vErr } = await supabase.from('vitals_logs').insert(allVitals)
  if (vErr) { console.error('vitals error:', vErr.message); process.exit(1) }
  console.log(`✅ Inserted ${allVitals.length} vitals records (14 days × 5 patients)`)

  // 3. Insert triage events
  const allTriage = PATIENTS.flatMap(triageEvents)
  if (allTriage.length) {
    const { error: tErr } = await supabase.from('triage_events').insert(allTriage)
    if (tErr) { console.error('triage error:', tErr.message); process.exit(1) }
    console.log(`✅ Inserted ${allTriage.length} triage events (risk patients)`)
  }

  // 4. Insert alerts
  const allAlerts = PATIENTS.flatMap(alertsForPatient)
  if (allAlerts.length) {
    const { error: aErr } = await supabase.from('alerts').insert(allAlerts)
    if (aErr) { console.error('alerts error:', aErr.message); process.exit(1) }
    console.log(`✅ Inserted ${allAlerts.length} unread alerts`)
  }

  console.log('\n🎉 Seed complete!')
  console.log('   Risk patients (Red tier): Shirin Sultana, Mina Parvin')
  console.log('   Provider UID for demo:   ', PROVIDER_ID)
}

seed().catch(console.error)
