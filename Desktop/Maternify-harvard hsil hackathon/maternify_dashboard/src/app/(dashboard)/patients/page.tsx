import { PatientPanel } from "@/components/patients/PatientPanel";
import { getDemoAlerts, getDemoPatients } from "@/lib/demo-data";

export default function PatientsPage() {
  const patients = getDemoPatients();
  const alerts = getDemoAlerts();
  const redCount = patients.filter(
    (patient) => patient.risk_tier === "red",
  ).length;
  const nusrat = patients.find((patient) => patient.id === "patient-nusrat");

  return (
    <div className="min-h-full bg-stone-50 p-6">
      <div className="mx-auto max-w-6xl space-y-6">
        <section className="rounded-3xl bg-slate-900 p-6 text-white shadow-sm">
          <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-2xl">
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-rose-200">
                Demo clinical queue
              </p>
              <h1 className="mt-3 text-3xl font-bold tracking-tight">
                Provider risk dashboard
              </h1>
              <p className="mt-3 text-sm leading-6 text-slate-200">
                This view is seeded to match the mobile demo. Nusrat should
                appear as the top RED patient with the same Bangla triage event,
                the same rising BP story, and the same urgent escalation
                context.
              </p>
            </div>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
              <MetricCard
                label="Active alerts"
                value={String(alerts.length)}
                accent="rose"
              />
              <MetricCard
                label="Red priority"
                value={String(redCount)}
                accent="red"
              />
              <MetricCard
                label="Queue owner"
                value="Dr. Fatema"
                accent="emerald"
              />
            </div>
          </div>
        </section>

        {nusrat && (
          <section className="rounded-3xl border border-red-200 bg-red-50 p-5 shadow-sm">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-red-700">
                  Immediate attention
                </p>
                <h2 className="mt-2 text-2xl font-bold text-red-950">
                  {nusrat.name} is already surfaced for review
                </h2>
                <p className="mt-2 max-w-2xl text-sm leading-6 text-red-900">
                  {nusrat.summary}
                </p>
              </div>
              <div className="rounded-2xl bg-white/90 p-4 text-sm text-red-950 shadow-sm">
                <p className="font-semibold">Demo handoff facts</p>
                <ul className="mt-2 space-y-1.5">
                  <li>
                    BP {nusrat.latest_systolic}/{nusrat.latest_diastolic} mmHg
                  </li>
                  <li>Bangla symptom: dizziness + blurred vision</li>
                  <li>SOS alert included in queue</li>
                </ul>
              </div>
            </div>
          </section>
        )}

        <section className="rounded-3xl border border-stone-200 bg-white p-5 shadow-sm">
          <div className="mb-5 flex items-center justify-between">
            <div>
              <h2 className="text-xl font-bold text-stone-900">
                Patient priority list
              </h2>
              <p className="mt-1 text-sm text-stone-500">
                Sorted by risk tier, ready for the live handoff from the
                emulator demo.
              </p>
            </div>
            {redCount > 0 && (
              <div className="rounded-full bg-red-600 px-4 py-2 text-sm font-bold text-white shadow-sm">
                {redCount} red alert{redCount > 1 ? "s" : ""}
              </div>
            )}
          </div>

          <PatientPanel patients={patients} />
        </section>
      </div>
    </div>
  );
}

function MetricCard({
  label,
  value,
  accent,
}: {
  label: string;
  value: string;
  accent: "rose" | "red" | "emerald";
}) {
  const tone = {
    rose: "bg-rose-100 text-rose-900",
    red: "bg-red-100 text-red-900",
    emerald: "bg-emerald-100 text-emerald-900",
  }[accent];

  return (
    <div className={`rounded-2xl ${tone} px-4 py-3`}>
      <p className="text-xs font-semibold uppercase tracking-wide opacity-70">
        {label}
      </p>
      <p className="mt-1 text-2xl font-bold">{value}</p>
    </div>
  );
}
