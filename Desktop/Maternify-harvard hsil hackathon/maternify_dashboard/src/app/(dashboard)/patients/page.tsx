import { PatientPanel } from '@/components/patients/PatientPanel'
import { supabase } from '@/lib/supabase'
import type { Patient, VitalsLog, TriageTier } from '@/types'

async function getPatientsWithRisk(): Promise<Patient[]> {
  // Fetch patients + their latest vitals + latest triage tier
  const { data: patients } = await supabase
    .from('patients')
    .select('*')
    .order('created_at', { ascending: false })

  if (!patients) return []

  // For each patient, get latest vitals and latest triage event
  const enriched = await Promise.all(
    patients.map(async (patient) => {
      const [vitalsRes, triageRes] = await Promise.all([
        supabase
          .from('vitals_logs')
          .select('systolic_bp, diastolic_bp')
          .eq('patient_id', patient.id)
          .order('logged_at', { ascending: false })
          .limit(1)
          .single(),
        supabase
          .from('triage_events')
          .select('triage_tier')
          .eq('patient_id', patient.id)
          .order('created_at', { ascending: false })
          .limit(1)
          .single(),
      ])

      return {
        ...patient,
        risk_tier: (triageRes.data?.triage_tier as TriageTier) ?? 'green',
        latest_systolic: vitalsRes.data?.systolic_bp,
        latest_diastolic: vitalsRes.data?.diastolic_bp,
      }
    })
  )

  return enriched
}

export default async function PatientsPage() {
  const patients = await getPatientsWithRisk()

  const redCount = patients.filter((p) => p.risk_tier === 'red').length

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Patients</h1>
          <p className="text-sm text-gray-500 mt-1">{patients.length} total · sorted by risk tier</p>
        </div>
        {redCount > 0 && (
          <div className="bg-red-500 text-white text-sm font-bold px-4 py-2 rounded-full animate-pulse">
            ⚠️ {redCount} Red Alert{redCount > 1 ? 's' : ''}
          </div>
        )}
      </div>

      <PatientPanel patients={patients} />
    </div>
  )
}

// Revalidate every 30s so risk tiers stay fresh without full SSR on every request
export const revalidate = 30
