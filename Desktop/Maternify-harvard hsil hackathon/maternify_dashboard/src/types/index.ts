export type TriageTier = 'green' | 'yellow' | 'red'

export interface Patient {
  id: string
  name: string
  age: number
  phone: string
  gravida: number
  parity: number
  weeks_gestation: number
  blood_type: string
  provider_id: string
  created_at: string
  // Computed — joined from latest vitals/triage
  risk_tier?: TriageTier
  latest_systolic?: number
  latest_diastolic?: number
}

export interface VitalsLog {
  id: string
  patient_id: string
  systolic_bp: number
  diastolic_bp: number
  weight_kg: number
  blood_glucose: number
  kick_count: number
  logged_at: string
}

export interface TriageEvent {
  id: string
  patient_id: string
  input_text: string
  input_lang: string
  triage_tier: TriageTier
  advice_bangla: string
  advice_english: string
  escalation_required: boolean
  suggested_action: string
  created_at: string
}

export interface EpdsScore {
  id: string
  patient_id: string
  score: number
  flagged: boolean
  administered_at: string
}

export interface Alert {
  id: string
  patient_id: string
  provider_id: string
  alert_type: string
  message: string
  read: boolean
  created_at: string
  patient?: Patient
}

export interface RiskScoreResponse {
  risk_tier: TriageTier
  probability: number
  shap_features: Array<{ feature: string; value: number; impact: number }>
}
