'use client'

import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell,
} from 'recharts'

// ── Types ──────────────────────────────────────────────────────────────────
export interface VitalsTrendPoint {
  day: string
  avgSystolic: number
  avgDiastolic: number
}

export interface TierCount {
  name: string
  value: number
  color: string
}

export interface EpdsHistogramBin {
  range: string
  count: number
  fill: string
}

export interface AlertVolumePoint {
  day: string
  count: number
}

export interface TopRiskPatient {
  id: string
  name: string
  tier: string
  latestEpds: number | null
  weeksGestation: number
  alertCount: number
}

interface Props {
  vitalsTrend: VitalsTrendPoint[]
  tierCounts: TierCount[]
  epdsHistogram: EpdsHistogramBin[]
  alertVolume: AlertVolumePoint[]
  topRisk: TopRiskPatient[]
}

// ── Tier badge ─────────────────────────────────────────────────────────────
function TierBadge({ tier }: { tier: string }) {
  const cfg: Record<string, string> = {
    red:    'bg-red-100 text-red-700 border border-red-200',
    yellow: 'bg-yellow-100 text-yellow-700 border border-yellow-200',
    green:  'bg-green-100 text-green-700 border border-green-200',
  }
  return (
    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold uppercase ${cfg[tier] ?? 'bg-gray-100 text-gray-600'}`}>
      {tier}
    </span>
  )
}

// ── Custom donut label ─────────────────────────────────────────────────────
function DonutLabel({ cx, cy, total }: { cx: number; cy: number; total: number }) {
  return (
    <>
      <text x={cx} y={cy - 8} textAnchor="middle" fill="#111827" className="text-lg font-bold" fontSize={22} fontWeight={700}>
        {total}
      </text>
      <text x={cx} y={cy + 14} textAnchor="middle" fill="#6b7280" fontSize={12}>
        patients
      </text>
    </>
  )
}

// ── Main export ────────────────────────────────────────────────────────────
export function AnalyticsCharts({ vitalsTrend, tierCounts, epdsHistogram, alertVolume, topRisk }: Props) {
  const totalPatients = tierCounts.reduce((s, t) => s + t.value, 0)

  return (
    <div className="space-y-6">

      {/* Row 1 — Tier donut + Top-risk table */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Triage Tier Distribution */}
        <div className="bg-white rounded-2xl border border-gray-200 p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Triage Tier Distribution</h2>
          <p className="text-xs text-gray-400 mb-4">Current tier across all patients</p>
          <div className="flex items-center gap-6">
            <ResponsiveContainer width={200} height={200}>
              <PieChart>
                <Pie
                  data={tierCounts}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  paddingAngle={3}
                  dataKey="value"
                >
                  {tierCounts.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                {/* centre label via custom shape trick */}
                <text x="50%" y="44%" textAnchor="middle" dominantBaseline="middle" fill="#111827" fontSize={22} fontWeight={700}>
                  {totalPatients}
                </text>
                <text x="50%" y="57%" textAnchor="middle" dominantBaseline="middle" fill="#6b7280" fontSize={12}>
                  patients
                </text>
                <Tooltip formatter={(v: number, name: string) => [`${v} patients`, name]} />
              </PieChart>
            </ResponsiveContainer>
            <div className="space-y-3 flex-1">
              {tierCounts.map((t) => (
                <div key={t.name} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="w-3 h-3 rounded-full" style={{ backgroundColor: t.color }} />
                    <span className="text-sm font-medium text-gray-700 capitalize">{t.name}</span>
                  </div>
                  <span className="text-sm font-bold text-gray-900">{t.value}</span>
                </div>
              ))}
              {totalPatients === 0 && (
                <p className="text-xs text-gray-400">No triage data yet</p>
              )}
            </div>
          </div>
        </div>

        {/* Top 5 Highest-Risk Patients */}
        <div className="bg-white rounded-2xl border border-gray-200 p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Top 5 Highest-Risk Patients</h2>
          <p className="text-xs text-gray-400 mb-4">Sorted by tier severity, then EPDS score</p>
          {topRisk.length === 0 ? (
            <p className="text-sm text-gray-400 py-8 text-center">No patient data available</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="text-xs text-gray-400 border-b">
                  <th className="text-left pb-2 font-medium">Patient</th>
                  <th className="text-left pb-2 font-medium">Tier</th>
                  <th className="text-right pb-2 font-medium">EPDS</th>
                  <th className="text-right pb-2 font-medium">Wk</th>
                  <th className="text-right pb-2 font-medium">Alerts</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {topRisk.map((p, i) => (
                  <tr key={p.id} className="hover:bg-gray-50 transition-colors">
                    <td className="py-2.5 pr-2">
                      <span className="font-medium text-gray-800">{p.name}</span>
                    </td>
                    <td className="py-2.5 pr-2"><TierBadge tier={p.tier} /></td>
                    <td className="py-2.5 text-right">
                      {p.latestEpds !== null ? (
                        <span className={`font-semibold ${p.latestEpds >= 12 ? 'text-red-600' : 'text-gray-700'}`}>
                          {p.latestEpds}
                        </span>
                      ) : (
                        <span className="text-gray-300">—</span>
                      )}
                    </td>
                    <td className="py-2.5 text-right text-gray-500">{p.weeksGestation}w</td>
                    <td className="py-2.5 text-right">
                      {p.alertCount > 0 ? (
                        <span className="bg-red-50 text-red-600 text-xs font-semibold px-1.5 py-0.5 rounded">
                          {p.alertCount}
                        </span>
                      ) : (
                        <span className="text-gray-300">0</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Row 2 — Vitals trend (full width) */}
      <div className="bg-white rounded-2xl border border-gray-200 p-5">
        <h2 className="text-base font-semibold text-gray-800 mb-1">Population Vitals Trend (14 days)</h2>
        <p className="text-xs text-gray-400 mb-4">Daily average systolic &amp; diastolic across all patients</p>
        {vitalsTrend.length < 2 ? (
          <div className="h-48 flex items-center justify-center text-gray-300 text-sm">Not enough vitals data yet</div>
        ) : (
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={vitalsTrend} margin={{ top: 5, right: 16, left: -16, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
              <XAxis dataKey="day" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} domain={[60, 'auto']} />
              <Tooltip
                contentStyle={{ fontSize: 12, borderRadius: 8, border: '1px solid #e5e7eb' }}
                formatter={(v: number, name: string) => [
                  `${Math.round(v)} mmHg`,
                  name === 'avgSystolic' ? 'Avg Systolic' : 'Avg Diastolic',
                ]}
              />
              <Legend
                wrapperStyle={{ fontSize: 12 }}
                formatter={(name) => (name === 'avgSystolic' ? 'Avg Systolic' : 'Avg Diastolic')}
              />
              <Line type="monotone" dataKey="avgSystolic"  stroke="#e91e8c" strokeWidth={2} dot={{ r: 3 }} activeDot={{ r: 5 }} />
              <Line type="monotone" dataKey="avgDiastolic" stroke="#9c27b0" strokeWidth={2} dot={{ r: 3 }} activeDot={{ r: 5 }} />
            </LineChart>
          </ResponsiveContainer>
        )}
      </div>

      {/* Row 3 — EPDS histogram + Alert volume */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* EPDS Score Histogram */}
        <div className="bg-white rounded-2xl border border-gray-200 p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">EPDS Score Distribution</h2>
          <p className="text-xs text-gray-400 mb-4">All-time screening scores · ≥12 = flagged for PPD</p>
          {epdsHistogram.every((b) => b.count === 0) ? (
            <div className="h-40 flex items-center justify-center text-gray-300 text-sm">No EPDS screenings yet</div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={epdsHistogram} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
                <XAxis dataKey="range" tick={{ fontSize: 11 }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                <Tooltip
                  contentStyle={{ fontSize: 12, borderRadius: 8, border: '1px solid #e5e7eb' }}
                  formatter={(v: number) => [`${v} screenings`, 'Count']}
                />
                <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                  {epdsHistogram.map((b, i) => (
                    <Cell key={i} fill={b.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
          <div className="flex gap-3 mt-3 flex-wrap">
            {[
              { label: '0–5 None',     color: '#22c55e' },
              { label: '6–10 Mild',    color: '#84cc16' },
              { label: '11–15 Mod.',   color: '#f59e0b' },
              { label: '16–20 M-Sev.', color: '#f97316' },
              { label: '21–30 Sev.',   color: '#ef4444' },
            ].map((l) => (
              <span key={l.label} className="flex items-center gap-1 text-xs text-gray-500">
                <span className="w-2.5 h-2.5 rounded-sm" style={{ backgroundColor: l.color }} />
                {l.label}
              </span>
            ))}
          </div>
        </div>

        {/* Alert Volume Over Time */}
        <div className="bg-white rounded-2xl border border-gray-200 p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Alert Volume (14 days)</h2>
          <p className="text-xs text-gray-400 mb-4">Daily alert count across all patients &amp; types</p>
          {alertVolume.every((d) => d.count === 0) ? (
            <div className="h-40 flex items-center justify-center text-gray-300 text-sm">No alerts in the last 14 days</div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={alertVolume} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
                <XAxis dataKey="day" tick={{ fontSize: 11 }} />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                <Tooltip
                  contentStyle={{ fontSize: 12, borderRadius: 8, border: '1px solid #e5e7eb' }}
                  formatter={(v: number) => [`${v} alerts`, 'Alerts']}
                />
                <Bar dataKey="count" fill="#f43f5e" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>
    </div>
  )
}
