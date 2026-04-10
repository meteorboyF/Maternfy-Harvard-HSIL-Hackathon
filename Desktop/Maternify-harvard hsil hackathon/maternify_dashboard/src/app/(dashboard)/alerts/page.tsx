import { AlertsClient } from "@/components/alerts/AlertsClient";
import { getDemoAlerts } from "@/lib/demo-data";

export default function AlertsPage() {
  const alerts = getDemoAlerts();
  const unreadCount = alerts.filter((alert) => !alert.read).length;

  return (
    <div className="min-h-full bg-stone-50 p-6">
      <div className="mx-auto max-w-5xl space-y-6">
        <section className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-stone-200">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600">
                Escalation feed
              </p>
              <h1 className="mt-2 text-3xl font-bold text-stone-950">
                Alert center
              </h1>
              <p className="mt-2 max-w-2xl text-sm leading-6 text-stone-600">
                Call patients directly, add clinical notes, and mark alerts as
                resolved to keep the queue clean.
              </p>
            </div>
            <div className="rounded-2xl bg-red-600 px-5 py-4 text-white shadow-sm">
              <p className="text-xs font-semibold uppercase tracking-wide text-red-100">
                Unread
              </p>
              <p className="mt-1 text-3xl font-bold">{unreadCount}</p>
            </div>
          </div>
        </section>

        <AlertsClient alerts={alerts} />
      </div>
    </div>
  );
}
