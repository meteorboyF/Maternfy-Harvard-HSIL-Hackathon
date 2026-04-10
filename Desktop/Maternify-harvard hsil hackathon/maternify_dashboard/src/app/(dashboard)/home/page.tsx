import Link from "next/link";

import { getDemoAlerts, getDemoPatients } from "@/lib/demo-data";

export default function HomePage() {
  const patients = getDemoPatients();
  const alerts = getDemoAlerts();

  const redPatients = patients.filter((p) => p.risk_tier === "red");
  const yellowPatients = patients.filter((p) => p.risk_tier === "yellow");
  const unreadAlerts = alerts.filter((a) => !a.read);

  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="min-h-full bg-stone-50 p-6">
      <div className="mx-auto max-w-5xl space-y-6">
        {/* Hero brief */}
        <section className="rounded-3xl bg-gradient-to-br from-rose-800 to-rose-600 p-7 text-white shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-[0.24em] text-rose-200">
            {today}
          </p>
          <h1 className="mt-3 text-3xl font-bold">Good morning, Dr. Fatema</h1>
          <p className="mt-2 text-sm leading-6 text-rose-100">
            {redPatients.length > 0
              ? `${redPatients.length} patient${redPatients.length > 1 ? "s" : ""} need${redPatients.length === 1 ? "s" : ""} immediate attention today.`
              : unreadAlerts.length > 0
                ? `No red-priority patients. You have ${unreadAlerts.length} unread alert${unreadAlerts.length > 1 ? "s" : ""}.`
                : "All patients are stable. No unread alerts."}
          </p>

          <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              {
                label: "Total patients",
                value: patients.length,
                bg: "bg-white/10",
              },
              {
                label: "Red priority",
                value: redPatients.length,
                bg:
                  redPatients.length > 0
                    ? "bg-red-500/40 ring-1 ring-red-300"
                    : "bg-white/10",
              },
              {
                label: "Yellow watch",
                value: yellowPatients.length,
                bg:
                  yellowPatients.length > 0
                    ? "bg-amber-500/30"
                    : "bg-white/10",
              },
              {
                label: "Unread alerts",
                value: unreadAlerts.length,
                bg: unreadAlerts.length > 0 ? "bg-white/20" : "bg-white/10",
              },
            ].map((stat) => (
              <div key={stat.label} className={`rounded-2xl ${stat.bg} px-4 py-3`}>
                <p className="text-xs font-semibold uppercase tracking-wide text-rose-100 opacity-80">
                  {stat.label}
                </p>
                <p className="mt-1 text-2xl font-bold">{stat.value}</p>
              </div>
            ))}
          </div>
        </section>

        {/* RED priority queue */}
        {redPatients.length > 0 && (
          <section className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-stone-200">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-bold text-stone-900">
                Immediate attention required
              </h2>
              <span className="animate-pulse rounded-full bg-red-600 px-3 py-1 text-xs font-bold text-white">
                {redPatients.length} RED
              </span>
            </div>
            <div className="space-y-3">
              {redPatients.map((patient) => (
                <div
                  key={patient.id}
                  className="flex flex-col gap-3 rounded-2xl border border-red-200 bg-red-50 p-4 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="flex items-start gap-3">
                    <div className="mt-1.5 h-3 w-3 shrink-0 animate-pulse rounded-full bg-red-500" />
                    <div>
                      <p className="font-semibold text-stone-900">
                        {patient.name}
                      </p>
                      <p className="text-xs text-stone-500">
                        {patient.weeks_gestation}w • G{patient.gravida}P
                        {patient.parity}
                      </p>
                      {patient.latest_systolic && (
                        <p className="mt-1 font-mono text-sm font-bold text-red-700">
                          BP {patient.latest_systolic}/{patient.latest_diastolic}{" "}
                          mmHg
                        </p>
                      )}
                      {patient.summary && (
                        <p className="mt-1 max-w-sm text-sm text-stone-600">
                          {patient.summary}
                        </p>
                      )}
                    </div>
                  </div>
                  <div className="flex shrink-0 gap-2">
                    <a
                      href={`tel:${patient.phone}`}
                      className="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-emerald-700"
                    >
                      📞 Call
                    </a>
                    <Link
                      href={`/patients/${patient.id}`}
                      className="flex items-center gap-1.5 rounded-xl border border-stone-300 bg-white px-4 py-2 text-sm font-semibold text-stone-700 transition-colors hover:bg-stone-50"
                    >
                      View →
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Yellow watch list */}
        {yellowPatients.length > 0 && (
          <section className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-stone-200">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-bold text-stone-900">
                Watch list — monitor today
              </h2>
              <span className="rounded-full border border-amber-300 bg-amber-100 px-3 py-1 text-xs font-bold text-amber-700">
                {yellowPatients.length} YELLOW
              </span>
            </div>
            <div className="space-y-3">
              {yellowPatients.map((patient) => (
                <div
                  key={patient.id}
                  className="flex flex-col gap-3 rounded-2xl border border-amber-200 bg-amber-50 p-4 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="flex items-start gap-3">
                    <div className="mt-1.5 h-3 w-3 shrink-0 rounded-full bg-amber-400" />
                    <div>
                      <p className="font-semibold text-stone-900">
                        {patient.name}
                      </p>
                      <p className="text-xs text-stone-500">
                        {patient.weeks_gestation}w • G{patient.gravida}P
                        {patient.parity}
                      </p>
                      {patient.summary && (
                        <p className="mt-1 max-w-sm text-sm text-stone-600">
                          {patient.summary}
                        </p>
                      )}
                    </div>
                  </div>
                  <div className="flex shrink-0 gap-2">
                    <a
                      href={`tel:${patient.phone}`}
                      className="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-emerald-700"
                    >
                      📞 Call
                    </a>
                    <Link
                      href={`/patients/${patient.id}`}
                      className="flex items-center gap-1.5 rounded-xl border border-stone-300 bg-white px-4 py-2 text-sm font-semibold text-stone-700 transition-colors hover:bg-stone-50"
                    >
                      View →
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Unread alerts preview */}
        {unreadAlerts.length > 0 && (
          <section className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-stone-200">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-bold text-stone-900">
                Unread alerts
              </h2>
              <Link
                href="/alerts"
                className="text-sm font-semibold text-rose-600 hover:text-rose-700"
              >
                View all {unreadAlerts.length} →
              </Link>
            </div>
            <div className="space-y-3">
              {unreadAlerts.slice(0, 3).map((alert) => (
                <div
                  key={alert.id}
                  className="rounded-2xl border border-stone-200 bg-stone-50 p-4"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="text-xs font-bold uppercase tracking-wide text-rose-600">
                        {alert.alert_type.replace(/_/g, " ")}
                      </p>
                      <p className="mt-1 font-semibold text-stone-900">
                        {alert.patient?.name ?? "Unknown patient"}
                      </p>
                      <p className="mt-1 text-sm leading-6 text-stone-600">
                        {alert.message}
                      </p>
                    </div>
                    {alert.patient?.phone && (
                      <a
                        href={`tel:${alert.patient.phone}`}
                        className="shrink-0 flex items-center gap-1.5 rounded-xl bg-emerald-600 px-3 py-2 text-sm font-bold text-white transition-colors hover:bg-emerald-700"
                      >
                        📞 Call
                      </a>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* All stable */}
        {redPatients.length === 0 && unreadAlerts.length === 0 && (
          <section className="rounded-3xl border border-emerald-200 bg-emerald-50 p-8 text-center shadow-sm">
            <p className="text-4xl">✅</p>
            <h2 className="mt-3 text-xl font-bold text-emerald-800">
              All patients stable
            </h2>
            <p className="mt-2 text-sm text-emerald-700">
              No unread alerts. No red-priority patients. Good work.
            </p>
            <Link
              href="/patients"
              className="mt-4 inline-flex items-center gap-2 rounded-xl bg-emerald-700 px-5 py-2 text-sm font-bold text-white hover:bg-emerald-800 transition-colors"
            >
              View all patients →
            </Link>
          </section>
        )}
      </div>
    </div>
  );
}
