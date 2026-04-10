"use client";

import { useState } from "react";
import Link from "next/link";

import type { Patient, TriageTier } from "@/types";

const TIER_STYLES: Record<
  TriageTier,
  { badge: string; row: string; dot: string }
> = {
  red: {
    badge: "border border-red-300 bg-red-100 text-red-700",
    row: "border-l-4 border-red-500 bg-red-50/60",
    dot: "bg-red-500 animate-pulse",
  },
  yellow: {
    badge: "border border-amber-300 bg-amber-100 text-amber-700",
    row: "border-l-4 border-amber-400 bg-amber-50/60",
    dot: "bg-amber-400",
  },
  green: {
    badge: "border border-emerald-300 bg-emerald-100 text-emerald-700",
    row: "border-l-4 border-emerald-400 bg-white",
    dot: "bg-emerald-500",
  },
};

const TIER_ORDER: Record<TriageTier, number> = { red: 0, yellow: 1, green: 2 };

interface Props {
  patients: Patient[];
  isLoading?: boolean;
}

export function PatientPanel({ patients, isLoading }: Props) {
  const [search, setSearch] = useState("");
  const [tierFilter, setTierFilter] = useState<TriageTier | "all">("all");

  const filtered = patients
    .filter((patient) => {
      const matchName = patient.name
        .toLowerCase()
        .includes(search.toLowerCase());
      const matchTier =
        tierFilter === "all" || patient.risk_tier === tierFilter;
      return matchName && matchTier;
    })
    .sort(
      (a, b) =>
        TIER_ORDER[a.risk_tier ?? "green"] - TIER_ORDER[b.risk_tier ?? "green"],
    );

  return (
    <div>
      <div className="mb-4 flex flex-wrap gap-3">
        <input
          type="text"
          placeholder="Search patients..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          className="min-w-48 flex-1 rounded-2xl border border-stone-300 px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-rose-400"
        />
        <div className="flex gap-2">
          {(["all", "red", "yellow", "green"] as const).map((tier) => (
            <button
              key={tier}
              onClick={() => setTierFilter(tier)}
              className={`rounded-2xl px-3 py-2 text-xs font-semibold capitalize transition-colors ${
                tierFilter === tier
                  ? "bg-rose-600 text-white"
                  : "bg-stone-100 text-stone-600 hover:bg-stone-200"
              }`}
            >
              {tier}
            </button>
          ))}
        </div>
      </div>

      <div className="mb-4 flex gap-3 text-sm">
        {(["red", "yellow", "green"] as TriageTier[]).map((tier) => {
          const count = patients.filter(
            (patient) => patient.risk_tier === tier,
          ).length;
          return (
            <span
              key={tier}
              className={`rounded-full px-3 py-1 text-xs font-bold uppercase ${TIER_STYLES[tier].badge}`}
            >
              {count} {tier}
            </span>
          );
        })}
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {[1, 2, 3, 4].map((index) => (
            <div
              key={index}
              className="h-24 animate-pulse rounded-2xl bg-stone-100"
            />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="py-12 text-center text-stone-400">
          No patients match the current filters.
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((patient) => {
            const tier = patient.risk_tier ?? "green";
            const style = TIER_STYLES[tier];

            return (
              <Link
                key={patient.id}
                href={`/patients/${patient.id}`}
                className={`block rounded-2xl p-5 shadow-sm transition-shadow hover:shadow-md ${style.row}`}
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-start gap-3">
                    <div className={`mt-2 h-3 w-3 rounded-full ${style.dot}`} />
                    <div>
                      <p className="text-lg font-semibold text-stone-900">
                        {patient.name}
                      </p>
                      <p className="text-xs text-stone-500">
                        {patient.weeks_gestation}w • G{patient.gravida}P
                        {patient.parity} • {patient.blood_type}
                      </p>
                      {patient.summary && (
                        <p className="mt-2 max-w-2xl text-sm leading-6 text-stone-600">
                          {patient.summary}
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex shrink-0 items-start gap-3">
                    <div className="text-right">
                      {patient.latest_systolic && (
                        <p
                          className={`text-sm font-mono font-bold ${
                            (patient.latest_systolic ?? 0) >= 140
                              ? "text-red-600"
                              : "text-stone-700"
                          }`}
                        >
                          {patient.latest_systolic}/{patient.latest_diastolic}
                        </p>
                      )}
                      <p className="mt-1 text-xs text-stone-500">
                        {patient.days_since_log ?? 0} day since last log
                      </p>
                    </div>
                    <span
                      className={`rounded-full px-3 py-1 text-xs font-bold uppercase ${style.badge}`}
                    >
                      {tier}
                    </span>
                    <span className="text-lg text-stone-400">›</span>
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
