"use client";

import { useEffect, useState } from "react";

import { formatDistanceToNow } from "date-fns";

import { getRiskBadgeTone } from "@/lib/demo-data";
import type { Alert, TriageTier } from "@/types";

type AlertStatus = "pending" | "called" | "resolved";

const ALERT_STYLES: Record<string, string> = {
  red_triage: "border-red-300 bg-red-50 text-red-950",
  sos_active: "border-red-400 bg-red-100 text-red-950",
  kick_count_low: "border-amber-300 bg-amber-50 text-amber-950",
};

const STATUS_STYLES: Record<AlertStatus, string> = {
  pending: "border border-stone-300 bg-stone-100 text-stone-600",
  called: "border border-amber-300 bg-amber-100 text-amber-700",
  resolved: "border border-emerald-300 bg-emerald-100 text-emerald-700",
};

const STATUS_LABELS: Record<AlertStatus, string> = {
  pending: "⏳ Pending",
  called: "📞 Called",
  resolved: "✅ Resolved",
};

export function AlertsClient({ alerts }: { alerts: Alert[] }) {
  const [statuses, setStatuses] = useState<Record<string, AlertStatus>>({});
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [expandedNote, setExpandedNote] = useState<string | null>(null);

  useEffect(() => {
    const savedStatuses = localStorage.getItem("maternify_alert_statuses");
    if (savedStatuses) setStatuses(JSON.parse(savedStatuses));

    const savedNotes = localStorage.getItem("maternify_alert_notes");
    if (savedNotes) setNotes(JSON.parse(savedNotes));
  }, []);

  const updateStatus = (alertId: string, status: AlertStatus) => {
    const next = { ...statuses, [alertId]: status };
    setStatuses(next);
    localStorage.setItem("maternify_alert_statuses", JSON.stringify(next));
  };

  const updateNote = (alertId: string, note: string) => {
    const next = { ...notes, [alertId]: note };
    setNotes(next);
    localStorage.setItem("maternify_alert_notes", JSON.stringify(next));
  };

  const resolvedCount = Object.values(statuses).filter(
    (s) => s === "resolved",
  ).length;
  const calledCount = Object.values(statuses).filter(
    (s) => s === "called",
  ).length;

  return (
    <div className="space-y-4">
      {(resolvedCount > 0 || calledCount > 0) && (
        <div className="flex gap-3 text-sm text-stone-500">
          {calledCount > 0 && (
            <span className="rounded-full border border-amber-300 bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700">
              📞 {calledCount} called
            </span>
          )}
          {resolvedCount > 0 && (
            <span className="rounded-full border border-emerald-300 bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
              ✅ {resolvedCount} resolved
            </span>
          )}
        </div>
      )}

      {alerts.map((alert) => {
        const patientTier = alert.patient?.risk_tier ?? "green";
        const status = statuses[alert.id] ?? "pending";
        const note = notes[alert.id] ?? "";
        const showNoteEditor = expandedNote === alert.id;

        return (
          <article
            key={alert.id}
            className={`rounded-3xl border p-5 shadow-sm transition-opacity ${
              status === "resolved" ? "opacity-50" : ""
            } ${ALERT_STYLES[alert.alert_type] ?? "border-stone-200 bg-white text-stone-900"}`}
          >
            <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
              {/* Left: meta + content */}
              <div className="flex-1 space-y-3">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="rounded-full bg-white/80 px-3 py-1 text-xs font-bold uppercase tracking-wide">
                    {alert.alert_type.replace(/_/g, " ")}
                  </span>
                  {alert.patient && (
                    <span
                      className={`rounded-full border px-3 py-1 text-xs font-bold uppercase tracking-wide ${getRiskBadgeTone(
                        patientTier as TriageTier,
                      )}`}
                    >
                      {patientTier} patient
                    </span>
                  )}
                  <span
                    className={`rounded-full px-3 py-1 text-xs font-bold ${STATUS_STYLES[status]}`}
                  >
                    {STATUS_LABELS[status]}
                  </span>
                </div>

                <div>
                  <h2 className="text-xl font-bold">
                    {alert.patient?.name ?? "Unknown patient"}
                  </h2>
                  <p className="mt-2 max-w-3xl text-sm leading-6">
                    {alert.message}
                  </p>

                  {/* Saved note display */}
                  {note && !showNoteEditor && (
                    <button
                      onClick={() => setExpandedNote(alert.id)}
                      className="mt-2 w-full rounded-xl bg-white/60 px-3 py-2 text-left text-sm italic text-stone-600 hover:bg-white/80 transition-colors"
                    >
                      📝 {note}
                    </button>
                  )}

                  {/* Note editor */}
                  {showNoteEditor && (
                    <textarea
                      autoFocus
                      value={note}
                      onChange={(e) => updateNote(alert.id, e.target.value)}
                      onBlur={() => setExpandedNote(null)}
                      placeholder="Clinical note — e.g. 'Called, advised bed rest. Follow up Friday.'"
                      className="mt-2 w-full resize-none rounded-xl border border-stone-300 bg-white p-3 text-sm text-stone-900 focus:outline-none focus:ring-2 focus:ring-rose-400"
                      rows={2}
                    />
                  )}
                </div>
              </div>

              {/* Right: time + actions */}
              <div className="flex flex-col items-end gap-3">
                <p className="text-sm font-medium opacity-70">
                  {formatDistanceToNow(new Date(alert.created_at), {
                    addSuffix: true,
                  })}
                </p>

                <div className="flex flex-wrap justify-end gap-2">
                  {alert.patient?.phone && (
                    <a
                      href={`tel:${alert.patient.phone}`}
                      onClick={() =>
                        status === "pending" && updateStatus(alert.id, "called")
                      }
                      className="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-emerald-700"
                    >
                      📞 Call
                    </a>
                  )}

                  <button
                    onClick={() =>
                      setExpandedNote(showNoteEditor ? null : alert.id)
                    }
                    className="rounded-xl border border-stone-300 bg-white/80 px-3 py-2 text-sm font-semibold text-stone-700 transition-colors hover:bg-stone-100"
                  >
                    ✏️ Note
                  </button>

                  {status !== "resolved" ? (
                    <button
                      onClick={() => updateStatus(alert.id, "resolved")}
                      className="rounded-xl bg-stone-800 px-3 py-2 text-sm font-bold text-white transition-colors hover:bg-stone-700"
                    >
                      ✓ Resolve
                    </button>
                  ) : (
                    <button
                      onClick={() => updateStatus(alert.id, "pending")}
                      className="rounded-xl border border-stone-300 bg-white px-3 py-2 text-xs font-semibold text-stone-500 transition-colors hover:bg-stone-50"
                    >
                      Reopen
                    </button>
                  )}
                </div>
              </div>
            </div>
          </article>
        );
      })}
    </div>
  );
}
