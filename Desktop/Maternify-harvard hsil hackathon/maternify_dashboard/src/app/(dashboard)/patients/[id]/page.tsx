import { notFound } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import type { Patient, VitalsLog, TriageEvent } from '@/types'
import { VitalsChart } from '@/components/charts/VitalsChart'
import { ShapExplainer } from '@/components/patients/ShapExplainer'
import { AiSummaryCard } from '@/components/patients/AiSummaryCard'
import { formatDistanceToNow } from 'date-fns'

async function getPatientDetail(id: string) {
  const [patientRes, vitalsRes, triageRes] = await Promise.all([
    supabase.from('patients').select('*').eq('id', id).single(),
    supabase
      .from('vitals_logs')
      .select('*')
      .eq('patient_id', id)
      .order('logged_at', { ascending: true })
      .limit(14),
    supabase
      .from('triage_events')
      .select('*')
      .eq('patient_id', id)
      .order('created_at', { ascending: false })
      .limit(5),
  ])

  if (patientRes.error || !patientRes.data) return null

  return {
    patient: patientRes.data as Patient,
    vitals: (vitalsRes.data ?? []) as VitalsLog[],
    triageHistory: (triageRes.data ?? []) as TriageEvent[],
  }
}

const TIER_STYLES = {
  red:    'bg-red-100 text-red-700 border-red-300',
  yellow: 'bg-yellow-100 text-yellow-700 border-yellow-300',
  green:  'bg-green-100 text-green-700 border-green-300',
}

export default async function PatientDetailPage({ params }: { params: { id: string } }) {
  const data = await getPatientDetail(params.id)
  if (!data) notFound()

  const { patient, vitals, triageHistory } = data
  const latestVitals = vitals[vitals.length - 1]
  const latestTriage = triageHistory[0]
  const tier = latestTriage?.triage_tier ?? 'green'

  return (
    <div className="p-6 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{patient.name}</h1>
          <p className="text-sm text-gray-500 mt-1">
            {patient.weeks_gestation}w gestation · G{patient.gravida}P{patient.parity} ·{' '}
            {patient.blood_type} · Age {patient.age}
          </p>
          <p className="text-xs text-gray-400 mt-1">📞 {patient.phone}</p>
        </div>
        <span className={`px-3 py-1 rounded-full text-sm font-bold border capitalize ${TIER_STYLES[tier as keyof typeof TIER_STYLES]}`}>
          {tier} risk
        </span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left column — vitals + chart */}
        <div className="lg:col-span-2 space-y-6">

          {/* Latest vitals strip */}
          {latestVitals && (
            <div className="bg-white rounded-xl border p-4 grid grid-cols-2 sm:grid-cols-4 gap-4">
              {[
                { label: 'Blood Pressure', value: `${latestVitals.systolic_bp}/${latestVitals.diastolic_bp}`, unit: 'mmHg', alert: latestVitals.systolic_bp >= 140 },
                { label: 'Weight',         value: latestVitals.weight_kg,     unit: 'kg',      alert: false },
                { label: 'Blood Glucose',  value: latestVitals.blood_glucose, unit: 'mmol/L',  alert: latestVitals.blood_glucose > 7.8 },
                { label: 'Kick Count',     value: latestVitals.kick_count,    unit: '/2h',     alert: latestVitals.kick_count < 10 },
              ].map(({ label, value, unit, alert }) => (
                <div key={label} className={`rounded-lg p-3 text-center ${alert ? 'bg-red-50 border border-red-200' : 'bg-gray-50'}`}>
                  <p className="text-xs text-gray-500 mb-1">{label}</p>
                  <p className={`text-xl font-bold ${alert ? 'text-red-600' : 'text-gray-800'}`}>{value}</p>
                  <p className="text-xs text-gray-400">{unit}</p>
                </div>
              ))}
            </div>
          )}

          {/* Vitals trend chart */}
          <div className="bg-white rounded-xl border p-4">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">BP Trend (last 14 days)</h2>
            <VitalsChart vitals={vitals} />
          </div>

          {/* Triage history */}
          <div className="bg-white rounded-xl border p-4">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">Recent Triage Events</h2>
            {triageHistory.length === 0 ? (
              <p className="text-gray-400 text-sm">No triage events yet</p>
            ) : (
              <div className="space-y-3">
                {triageHistory.map((t) => (
                  <div key={t.id} className={`rounded-lg p-3 border ${TIER_STYLES[t.triage_tier as keyof typeof TIER_STYLES]}`}>
                    <div className="flex justify-between items-start mb-1">
                      <span className="text-xs font-bold uppercase">{t.triage_tier}</span>
                      <span className="text-xs opacity-60">
                        {formatDistanceToNow(new Date(t.created_at), { addSuffix: true })}
                      </span>
                    </div>
                    <p className="text-sm font-medium mb-1">"{t.input_text}"</p>
                    <p className="text-xs opacity-70">{t.advice_english}</p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right column — AI summary + SHAP */}
        <div className="space-y-6">
          <AiSummaryCard patientId={patient.id} patientName={patient.name} />
          <ShapExplainer patientId={patient.id} patient={patient} latestVitals={latestVitals} />
        </div>
      </div>
    </div>
  )
}

export const revalidate = 60
