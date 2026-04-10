import { formatDistanceToNow } from "date-fns";
import { notFound } from "next/navigation";

import { AiSummaryCard } from "@/components/patients/AiSummaryCard";
import { ClinicalNotes } from "@/components/patients/ClinicalNotes";
import { ShapExplainer } from "@/components/patients/ShapExplainer";
import { VitalsChart } from "@/components/charts/VitalsChart";
import { getDemoPatientRecord, getRiskBadgeTone } from "@/lib/demo-data";

export default function PatientDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const record = getDemoPatientRecord(params.id);
  if (!record) notFound();

  const { patient, vitals, triageHistory, aiSummary } = record;
  const latestVitals = vitals[vitals.length - 1];
  const tier = patient.risk_tier ?? "green";

  return (
    <div className="min-h-full bg-stone-50 p-6">
      <div className="mx-auto max-w-6xl space-y-6">
        <section className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-stone-200">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600">
                Maternal record
              </p>
              <h1 className="mt-2 text-3xl font-bold text-stone-950">
                {patient.name}
              </h1>
              <p className="mt-2 text-sm text-stone-500">
                {patient.weeks_gestation}w gestation • G{patient.gravida}P
                {patient.parity} • {patient.blood_type} • Age {patient.age}
              </p>
              <div className="mt-2 flex items-center gap-3">
                <p className="text-sm text-stone-500">{patient.phone}</p>
                <a
                  href={`tel:${patient.phone}`}
                  className="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-emerald-700"
                >
                  📞 Call patient
                </a>
              </div>
            </div>
            <div className="space-y-3">
              <span
                className={`inline-flex rounded-full border px-4 py-2 text-sm font-bold uppercase tracking-wide ${getRiskBadgeTone(
                  tier,
                )}`}
              >
                {tier} risk
              </span>
              <p className="max-w-sm text-sm leading-6 text-stone-600">
                {record.summary}
              </p>
            </div>
          </div>
        </section>

        <div className="grid gap-6 lg:grid-cols-[1.5fr_1fr]">
          <div className="space-y-6">
            {latestVitals && (
              <section className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-stone-200">
                <h2 className="text-lg font-bold text-stone-900">
                  Latest vitals snapshot
                </h2>
                <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                  {[
                    {
                      label: "Blood pressure",
                      value: `${latestVitals.systolic_bp}/${latestVitals.diastolic_bp}`,
                      unit: "mmHg",
                      danger:
                        latestVitals.systolic_bp >= 140 ||
                        latestVitals.diastolic_bp >= 90,
                    },
                    {
                      label: "Weight",
                      value: latestVitals.weight_kg,
                      unit: "kg",
                      danger: false,
                    },
                    {
                      label: "Glucose",
                      value: latestVitals.blood_glucose,
                      unit: "mmol/L",
                      danger: latestVitals.blood_glucose > 7.8,
                    },
                    {
                      label: "Kick count",
                      value: latestVitals.kick_count,
                      unit: "/2h",
                      danger: latestVitals.kick_count < 10,
                    },
                  ].map((item) => (
                    <div
                      key={item.label}
                      className={`rounded-2xl border px-4 py-4 ${
                        item.danger
                          ? "border-red-200 bg-red-50 text-red-900"
                          : "border-stone-200 bg-stone-50 text-stone-900"
                      }`}
                    >
                      <p className="text-xs font-semibold uppercase tracking-wide opacity-70">
                        {item.label}
                      </p>
                      <p className="mt-3 text-2xl font-bold">{item.value}</p>
                      <p className="text-xs opacity-60">{item.unit}</p>
                    </div>
                  ))}
                </div>
              </section>
            )}

            <section className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-stone-200">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-bold text-stone-900">
                  14-day vitals trend
                </h2>
                <p className="text-sm text-stone-500">
                  Used to justify the live RED escalation
                </p>
              </div>
              <VitalsChart vitals={vitals} />
            </section>

            <section className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-stone-200">
              <h2 className="text-lg font-bold text-stone-900">
                Recent triage history
              </h2>
              <div className="mt-4 space-y-3">
                {triageHistory.map((event) => (
                  <article
                    key={event.id}
                    className={`rounded-2xl border p-4 ${getRiskBadgeTone(event.triage_tier)}`}
                  >
                    <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <p className="text-xs font-bold uppercase tracking-wide">
                          {event.triage_tier} triage
                        </p>
                        <p className="mt-2 text-lg font-semibold">
                          “{event.input_text}”
                        </p>
                        <p className="mt-2 text-sm leading-6">
                          {event.advice_english}
                        </p>
                      </div>
                      <p className="text-sm opacity-70">
                        {formatDistanceToNow(new Date(event.created_at), {
                          addSuffix: true,
                        })}
                      </p>
                    </div>
                  </article>
                ))}
              </div>
            </section>
          </div>

          <div className="space-y-6">
            <AiSummaryCard
              patientId={patient.id}
              patientName={patient.name}
              initialSummary={aiSummary}
            />
            <ShapExplainer
              patientId={patient.id}
              patient={patient}
              latestVitals={latestVitals}
              demoRiskFactors={record.riskFactors}
            />
            <ClinicalNotes patientId={patient.id} />
          </div>
        </div>
      </div>
    </div>
  );
}
