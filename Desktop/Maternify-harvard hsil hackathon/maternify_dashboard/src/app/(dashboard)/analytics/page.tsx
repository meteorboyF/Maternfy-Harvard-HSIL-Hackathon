import { supabase } from '@/lib/supabase'
import { format, subDays, eachDayOfInterval } from 'date-fns'
import { AnalyticsCharts } from '@/components/analytics/AnalyticsCharts'
import { getDemoPatients, getDemoAlerts } from '@/lib/demo-data'
import type {
  VitalsTrendPoint,
  TierCount,
  EpdsHistogramBin,
  AlertVolumePoint,
  TopRiskPatient,
} from '@/components/analytics/AnalyticsCharts'

// ── Demo fallback — builds analytics from seed JSON when Supabase is empty ─
function buildDemoAnalytics() {
  const demoPatients = getDemoPatients()
  const demoAlerts   = getDemoAlerts()

  // Collect all vitals from seed via demo-data helper (import seed directly)
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const seed = require('../../../maternify_app/assets/demo/demo_seed.json') as {
    patient_records: Record<string, { vitals: Array<{ systolic_bp: number; diastolic_bp: number; logged_at: string }>; triage_history: Array<{ triage_tier: string; patient_id: string }> }>
  }

  const allVitals = Object.values(seed.patient_records).flatMap((r) => r.vitals)
  const allTriage = Object.values(seed.patient_records).flatMap((r) => r.triage_history)

  // 1. Vitals trend
  const now  = new Date()
  const days = eachDayOfInterval({ start: subDays(now, 13), end: now })
  const vitalsByDay: Record<string, { sum_s: number; sum_d: number; n: number }> = {}
  days.forEach((d) => { vitalsByDay[format(d, 'MM/dd')] = { sum_s: 0, sum_d: 0, n: 0 } })
  allVitals.forEach((v) => {
    const key = format(new Date(v.logged_at), 'MM/dd')
    if (vitalsByDay[key]) {
      vitalsByDay[key].sum_s += v.systolic_bp
      vitalsByDay[key].sum_d += v.diastolic_bp
      vitalsByDay[key].n    += 1
    }
  })
  const vitalsTrend: VitalsTrendPoint[] = days.map((d) => {
    const key = format(d, 'MM/dd')
    const { sum_s, sum_d, n } = vitalsByDay[key]
    return {
      day:          key,
      avgSystolic:  n > 0 ? Math.round((sum_s / n) * 10) / 10 : 0,
      avgDiastolic: n > 0 ? Math.round((sum_d / n) * 10) / 10 : 0,
    }
  }).filter((p) => p.avgSystolic > 0)

  // 2. Tier counts from patients
  const tierCounts: TierCount[] = [
    { name: 'Red',    value: demoPatients.filter((p) => p.risk_tier === 'red').length,    color: '#ef4444' },
    { name: 'Yellow', value: demoPatients.filter((p) => p.risk_tier === 'yellow').length, color: '#f59e0b' },
    { name: 'Green',  value: demoPatients.filter((p) => p.risk_tier === 'green').length,  color: '#22c55e' },
  ]

  // 3. EPDS histogram — no EPDS in seed, show empty bins
  const epdsHistogram: EpdsHistogramBin[] = [
    { range: '0–5',   count: 0, fill: '#22c55e' },
    { range: '6–10',  count: 0, fill: '#84cc16' },
    { range: '11–15', count: 0, fill: '#f59e0b' },
    { range: '16–20', count: 0, fill: '#f97316' },
    { range: '21–30', count: 0, fill: '#ef4444' },
  ]

  // 4. Alert volume — place alerts on their actual days
  const alertByDay: Record<string, number> = {}
  days.forEach((d) => { alertByDay[format(d, 'MM/dd')] = 0 })
  demoAlerts.forEach((a) => {
    const key = format(new Date(a.created_at), 'MM/dd')
    if (key in alertByDay) alertByDay[key]++
  })
  const alertVolume: AlertVolumePoint[] = days.map((d) => ({
    day:   format(d, 'MM/dd'),
    count: alertByDay[format(d, 'MM/dd')] ?? 0,
  }))

  // 5. Top risk patients
  const tierRank: Record<string, number> = { red: 0, yellow: 1, green: 2 }
  const alertCountPerPatient: Record<string, number> = {}
  demoAlerts.forEach((a) => {
    alertCountPerPatient[a.patient_id] = (alertCountPerPatient[a.patient_id] ?? 0) + 1
  })
  const latestTierPerPatient: Record<string, string> = {}
  allTriage.forEach((t) => {
    if (!latestTierPerPatient[t.patient_id]) latestTierPerPatient[t.patient_id] = t.triage_tier
  })
  const topRisk: TopRiskPatient[] = demoPatients
    .map((p) => ({
      id:             p.id,
      name:           p.name,
      tier:           latestTierPerPatient[p.id] ?? p.risk_tier ?? 'green',
      latestEpds:     null,
      weeksGestation: p.weeks_gestation,
      alertCount:     alertCountPerPatient[p.id] ?? 0,
    }))
    .sort((a, b) => (tierRank[a.tier] ?? 2) - (tierRank[b.tier] ?? 2))
    .slice(0, 5)

  return { vitalsTrend, tierCounts, epdsHistogram, alertVolume, topRisk }
}

// ── Data fetching ──────────────────────────────────────────────────────────
async function getAnalyticsData() {
  const now = new Date()
  const fourteenDaysAgo = subDays(now, 14).toISOString()

  const [vitalsRes, triageRes, epdsRes, alertsRes, patientsRes] = await Promise.all([
    supabase
      .from('vitals_logs')
      .select('systolic_bp, diastolic_bp, logged_at')
      .gte('logged_at', fourteenDaysAgo)
      .order('logged_at'),
    supabase
      .from('triage_events')
      .select('triage_tier, patient_id, created_at')
      .order('created_at', { ascending: false }),
    supabase
      .from('epds_scores')
      .select('score, patient_id, administered_at'),
    supabase
      .from('alerts')
      .select('created_at, patient_id, alert_type')
      .gte('created_at', fourteenDaysAgo),
    supabase
      .from('patients')
      .select('id, name, weeks_gestation'),
  ])

  const vitalsRaw  = vitalsRes.data  ?? []
  const triageRaw  = triageRes.data  ?? []
  const epdsRaw    = epdsRes.data    ?? []
  const alertsRaw  = alertsRes.data  ?? []
  const patients   = patientsRes.data ?? []

  // ── Demo fallback — if Supabase has no data, derive from seed ──────────
  const isEmpty = vitalsRaw.length === 0 && triageRaw.length === 0 && patients.length === 0
  if (isEmpty) {
    return buildDemoAnalytics()
  }

  // ── 1. Vitals trend — daily average systolic/diastolic ─────────────────
  const days = eachDayOfInterval({ start: subDays(now, 13), end: now })
  const vitalsByDay: Record<string, { sum_s: number; sum_d: number; n: number }> = {}
  days.forEach((d) => {
    vitalsByDay[format(d, 'MM/dd')] = { sum_s: 0, sum_d: 0, n: 0 }
  })
  vitalsRaw.forEach((v) => {
    const key = format(new Date(v.logged_at), 'MM/dd')
    if (vitalsByDay[key]) {
      vitalsByDay[key].sum_s += v.systolic_bp
      vitalsByDay[key].sum_d += v.diastolic_bp
      vitalsByDay[key].n    += 1
    }
  })
  const vitalsTrend: VitalsTrendPoint[] = days.map((d) => {
    const key = format(d, 'MM/dd')
    const { sum_s, sum_d, n } = vitalsByDay[key]
    return {
      day: key,
      avgSystolic:  n > 0 ? Math.round((sum_s / n) * 10) / 10 : 0,
      avgDiastolic: n > 0 ? Math.round((sum_d / n) * 10) / 10 : 0,
    }
  }).filter((p) => p.avgSystolic > 0 || p.avgDiastolic > 0)

  // ── 2. Triage tier distribution — latest event per patient ─────────────
  const latestTierPerPatient: Record<string, string> = {}
  triageRaw.forEach((t) => {
    if (!latestTierPerPatient[t.patient_id]) {
      latestTierPerPatient[t.patient_id] = t.triage_tier
    }
  })
  const tierCounts: TierCount[] = [
    { name: 'Red',    value: 0, color: '#ef4444' },
    { name: 'Yellow', value: 0, color: '#f59e0b' },
    { name: 'Green',  value: 0, color: '#22c55e' },
  ]
  Object.values(latestTierPerPatient).forEach((tier) => {
    if (tier === 'red')    tierCounts[0].value++
    else if (tier === 'yellow') tierCounts[1].value++
    else if (tier === 'green')  tierCounts[2].value++
  })

  // ── 3. EPDS histogram — bin all-time scores ────────────────────────────
  const bins = [
    { range: '0–5',   min: 0,  max: 5,  fill: '#22c55e', count: 0 },
    { range: '6–10',  min: 6,  max: 10, fill: '#84cc16', count: 0 },
    { range: '11–15', min: 11, max: 15, fill: '#f59e0b', count: 0 },
    { range: '16–20', min: 16, max: 20, fill: '#f97316', count: 0 },
    { range: '21–30', min: 21, max: 30, fill: '#ef4444', count: 0 },
  ]
  epdsRaw.forEach((e) => {
    const bin = bins.find((b) => e.score >= b.min && e.score <= b.max)
    if (bin) bin.count++
  })
  const epdsHistogram: EpdsHistogramBin[] = bins.map(({ range, count, fill }) => ({ range, count, fill }))

  // ── 4. Alert volume — count per day over 14 days ──────────────────────
  const alertByDay: Record<string, number> = {}
  days.forEach((d) => { alertByDay[format(d, 'MM/dd')] = 0 })
  alertsRaw.forEach((a) => {
    const key = format(new Date(a.created_at), 'MM/dd')
    if (key in alertByDay) alertByDay[key]++
  })
  const alertVolume: AlertVolumePoint[] = days.map((d) => ({
    day:   format(d, 'MM/dd'),
    count: alertByDay[format(d, 'MM/dd')] ?? 0,
  }))

  // ── 5. Top 5 highest-risk patients ────────────────────────────────────
  const tierRank: Record<string, number> = { red: 0, yellow: 1, green: 2 }
  const latestEpdsPerPatient: Record<string, number> = {}
  epdsRaw.forEach((e) => {
    if (latestEpdsPerPatient[e.patient_id] === undefined) {
      latestEpdsPerPatient[e.patient_id] = e.score
    }
  })
  const alertCountPerPatient: Record<string, number> = {}
  alertsRaw.forEach((a) => {
    alertCountPerPatient[a.patient_id] = (alertCountPerPatient[a.patient_id] ?? 0) + 1
  })

  const topRisk: TopRiskPatient[] = patients
    .map((p) => ({
      id:             p.id,
      name:           p.name,
      tier:           latestTierPerPatient[p.id] ?? 'green',
      latestEpds:     latestEpdsPerPatient[p.id] ?? null,
      weeksGestation: p.weeks_gestation,
      alertCount:     alertCountPerPatient[p.id] ?? 0,
    }))
    .sort((a, b) => {
      const tierDiff = (tierRank[a.tier] ?? 2) - (tierRank[b.tier] ?? 2)
      if (tierDiff !== 0) return tierDiff
      // secondary: higher EPDS = more at risk
      return (b.latestEpds ?? -1) - (a.latestEpds ?? -1)
    })
    .slice(0, 5)

  return { vitalsTrend, tierCounts, epdsHistogram, alertVolume, topRisk }
}

// ── Stat card ──────────────────────────────────────────────────────────────
function StatCard({ label, value, sub, accent }: { label: string; value: string | number; sub?: string; accent?: string }) {
  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-5">
      <p className="text-xs font-medium text-gray-400 uppercase tracking-wide">{label}</p>
      <p className={`text-3xl font-bold mt-1 ${accent ?? 'text-gray-900'}`}>{value}</p>
      {sub && <p className="text-xs text-gray-400 mt-1">{sub}</p>}
    </div>
  )
}

// ── Page ───────────────────────────────────────────────────────────────────
export default async function AnalyticsPage() {
  const { vitalsTrend, tierCounts, epdsHistogram, alertVolume, topRisk } = await getAnalyticsData()

  const totalPatients = tierCounts.reduce((s, t) => s + t.value, 0)
  const redCount      = tierCounts.find((t) => t.name === 'Red')?.value ?? 0
  const flaggedEpds   = epdsHistogram.filter((b) => ['11–15', '16–20', '21–30'].includes(b.range)).reduce((s, b) => s + b.count, 0)
  const totalAlerts   = alertVolume.reduce((s, a) => s + a.count, 0)

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
        <p className="text-sm text-gray-500 mt-1">Population-level insights · last 14 days</p>
      </div>

      {/* KPI strip */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard label="Total Patients"   value={totalPatients}  sub="under active monitoring" />
        <StatCard label="Red Alerts"       value={redCount}       sub="requiring immediate attention" accent={redCount > 0 ? 'text-red-600' : undefined} />
        <StatCard label="EPDS Flagged"     value={flaggedEpds}    sub="score ≥ 11 (all time)" accent={flaggedEpds > 0 ? 'text-amber-600' : undefined} />
        <StatCard label="Alerts (14d)"     value={totalAlerts}    sub="across all patients" />
      </div>

      {/* Charts */}
      <AnalyticsCharts
        vitalsTrend={vitalsTrend}
        tierCounts={tierCounts}
        epdsHistogram={epdsHistogram}
        alertVolume={alertVolume}
        topRisk={topRisk}
      />
    </div>
  )
}

// Revalidate every 60s — analytics are less time-critical than the patient panel
export const revalidate = 60
