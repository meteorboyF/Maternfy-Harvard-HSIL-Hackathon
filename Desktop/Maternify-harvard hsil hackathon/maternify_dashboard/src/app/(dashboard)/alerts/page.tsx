'use client'

import { useRealtimeAlerts } from '@/lib/useAlerts'
import { formatDistanceToNow } from 'date-fns'

// Demo provider id — replaced with real auth.uid() in F14
const DEMO_PROVIDER_ID = 'demo-provider-uid-001'

const TIER_COLORS: Record<string, string> = {
  red_triage:       'bg-red-100 border-red-400 text-red-800',
  bp_critical:      'bg-red-100 border-red-400 text-red-800',
  epds_flagged:     'bg-purple-100 border-purple-400 text-purple-800',
  kick_count_low:   'bg-yellow-100 border-yellow-400 text-yellow-800',
  anomaly_detected: 'bg-orange-100 border-orange-400 text-orange-800',
}

export default function AlertsPage() {
  const { alerts, unreadCount, loading } = useRealtimeAlerts(DEMO_PROVIDER_ID)

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Real-time Alerts</h1>
          <p className="text-sm text-gray-500 mt-1">Live from Firestore — updates in &lt;2s</p>
        </div>
        {unreadCount > 0 && (
          <span className="bg-red-500 text-white text-sm font-bold px-3 py-1 rounded-full animate-pulse">
            {unreadCount} unread
          </span>
        )}
      </div>

      {loading && (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-20 bg-gray-100 rounded-lg animate-pulse" />
          ))}
        </div>
      )}

      {!loading && alerts.length === 0 && (
        <div className="text-center py-16 text-gray-400">
          <span className="text-5xl">✅</span>
          <p className="mt-4 text-lg">No unread alerts</p>
        </div>
      )}

      <div className="space-y-3">
        {alerts.map((alert) => (
          <div
            key={alert.id}
            className={`border-l-4 rounded-lg p-4 ${TIER_COLORS[alert.alert_type] || 'bg-gray-100 border-gray-400'}`}
          >
            <div className="flex justify-between items-start">
              <div>
                <span className="text-xs font-semibold uppercase tracking-wide opacity-70">
                  {alert.alert_type.replace('_', ' ')}
                </span>
                <p className="font-medium mt-1">{alert.message}</p>
              </div>
              <span className="text-xs opacity-60 whitespace-nowrap ml-4">
                {alert.created_at
                  ? formatDistanceToNow(new Date(alert.created_at), { addSuffix: true })
                  : '—'}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
