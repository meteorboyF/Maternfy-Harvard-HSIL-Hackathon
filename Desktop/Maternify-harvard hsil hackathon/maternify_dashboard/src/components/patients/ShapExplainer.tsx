"use client";

import { useEffect, useState } from "react";
import type { Patient, VitalsLog, RiskScoreResponse } from "@/types";

interface Props {
  patientId: string;
  patient: Patient;
  latestVitals?: VitalsLog;
  demoRiskFactors?: Array<{ feature: string; value: number; impact: number }>;
}

const FEATURE_LABELS: Record<string, string> = {
  systolic_bp: "Systolic BP",
  diastolic_bp: "Diastolic BP",
  blood_glucose: "Blood Glucose",
  kick_count: "Kick Count",
  weight_kg: "Weight",
  weeks_gestation: "Gestational Age",
  age: "Maternal Age",
  gravida: "Gravida",
  parity: "Parity",
};

const TIER_COLORS = {
  red: "bg-red-500",
  yellow: "bg-yellow-400",
  green: "bg-green-500",
};

export function ShapExplainer({
  patientId,
  patient,
  latestVitals,
  demoRiskFactors,
}: Props) {
  const [risk, setRisk] = useState<RiskScoreResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (demoRiskFactors?.length) {
      setRisk({
        risk_tier: patient.risk_tier ?? "green",
        probability:
          patient.risk_tier === "red"
            ? 0.94
            : patient.risk_tier === "yellow"
              ? 0.68
              : 0.22,
        shap_features: demoRiskFactors,
      });
      setLoading(false);
      return;
    }

    if (!latestVitals) {
      setLoading(false);
      return;
    }

    const fetchRisk = async () => {
      try {
        const res = await fetch(
          `${process.env.NEXT_PUBLIC_ML_SERVICE_URL || "http://localhost:8000"}/risk-score/`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              patient_id: patientId,
              age: patient.age,
              weeks_gestation: patient.weeks_gestation,
              gravida: patient.gravida,
              parity: patient.parity,
              vitals: {
                systolic_bp: latestVitals.systolic_bp,
                diastolic_bp: latestVitals.diastolic_bp,
                weight_kg: latestVitals.weight_kg,
                blood_glucose: latestVitals.blood_glucose,
                kick_count: latestVitals.kick_count,
              },
            }),
          },
        );
        const data = await res.json();
        setRisk(data);
      } catch {
        // ML service not running — show placeholder
      } finally {
        setLoading(false);
      }
    };
    fetchRisk();
  }, [demoRiskFactors, latestVitals, patient.risk_tier, patientId]);

  return (
    <div className="bg-white rounded-xl border p-4">
      <h2 className="text-sm font-semibold text-gray-700 mb-3">
        ML Risk Explanation
      </h2>

      {loading && <div className="h-20 bg-gray-100 rounded animate-pulse" />}

      {!loading && !risk && (
        <p className="text-xs text-gray-400">
          ML service offline — start FastAPI on :8000
        </p>
      )}

      {risk && (
        <div className="space-y-3">
          {/* Risk tier + probability */}
          <div className="flex items-center gap-2">
            <div
              className={`w-3 h-3 rounded-full ${TIER_COLORS[risk.risk_tier as keyof typeof TIER_COLORS]}`}
            />
            <span className="font-bold capitalize text-sm">
              {risk.risk_tier} risk
            </span>
            <span className="text-xs text-gray-400 ml-auto">
              {(risk.probability * 100).toFixed(0)}% confidence
            </span>
          </div>

          {/* SHAP bars */}
          <div>
            <p className="text-xs text-gray-500 mb-2">
              Top contributing factors:
            </p>
            {risk.shap_features.slice(0, 3).map((f) => {
              const maxImpact = Math.max(
                ...risk.shap_features.map((x) => Math.abs(x.impact)),
              );
              const pct =
                maxImpact > 0 ? (Math.abs(f.impact) / maxImpact) * 100 : 0;
              const isPositive = f.impact > 0;
              return (
                <div key={f.feature} className="mb-2">
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gray-600">
                      {FEATURE_LABELS[f.feature] ?? f.feature}
                    </span>
                    <span
                      className={isPositive ? "text-red-500" : "text-green-600"}
                    >
                      {isPositive ? "↑" : "↓"} {f.value}
                    </span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${isPositive ? "bg-red-400" : "bg-green-400"}`}
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
