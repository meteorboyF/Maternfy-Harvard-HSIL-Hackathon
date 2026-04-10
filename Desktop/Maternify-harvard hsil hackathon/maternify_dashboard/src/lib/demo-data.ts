import seed from "../../../maternify_app/assets/demo/demo_seed.json";

import type {
  Alert,
  Patient,
  TriageEvent,
  TriageTier,
  VitalsLog,
} from "@/types";

type RiskFactor = { feature: string; value: number; impact: number };

interface SeedPatient extends Patient {
  summary: string;
  days_since_log: number;
}

interface DemoSeedRecord {
  ai_summary: string;
  risk_factors: RiskFactor[];
  vitals: VitalsLog[];
  triage_history: TriageEvent[];
}

export interface DemoPatientRecord {
  patient: Patient;
  summary: string;
  aiSummary: string;
  riskFactors: RiskFactor[];
  vitals: VitalsLog[];
  triageHistory: TriageEvent[];
  daysSinceLog: number;
}

const patients = seed.patients as SeedPatient[];
const patientRecords = seed.patient_records as Record<string, DemoSeedRecord>;

export function getDemoPatients(): Patient[] {
  return patients.map((patient) => ({
    ...patient,
    summary: patient.summary,
    days_since_log: patient.days_since_log,
  }));
}

export function getDemoPatientRecord(id: string): DemoPatientRecord | null {
  const patient = patients.find((entry) => entry.id === id);
  const record = patientRecords[id];

  if (!patient || !record) return null;

  return {
    patient,
    summary: patient.summary,
    aiSummary: record.ai_summary,
    riskFactors: record.risk_factors,
    vitals: record.vitals,
    triageHistory: record.triage_history,
    daysSinceLog: patient.days_since_log,
  };
}

export function getDemoAlerts(): Alert[] {
  return (seed.alerts as Alert[]).map((alert) => ({
    ...alert,
    patient: patients.find((patient) => patient.id === alert.patient_id),
  }));
}

export function getDemoUnreadCount() {
  return getDemoAlerts().filter((alert) => !alert.read).length;
}

export function getRiskBadgeTone(tier: TriageTier) {
  return {
    red: "bg-red-100 text-red-700 border-red-300",
    yellow: "bg-amber-100 text-amber-700 border-amber-300",
    green: "bg-emerald-100 text-emerald-700 border-emerald-300",
  }[tier];
}
