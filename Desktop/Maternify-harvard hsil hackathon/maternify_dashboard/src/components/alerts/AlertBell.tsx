'use client'

import Link from 'next/link'
import { useRealtimeAlerts } from '@/lib/useAlerts'

// Demo provider — replaced with auth.currentUser.uid in F17
const DEMO_PROVIDER_ID = 'demo-provider-uid-001'

export function AlertBell() {
  const { unreadCount } = useRealtimeAlerts(DEMO_PROVIDER_ID)

  return (
    <Link href="/alerts" className="relative p-2 rounded-lg hover:bg-pink-50 transition-colors">
      <span className="text-xl">🔔</span>
      {unreadCount > 0 && (
        <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold w-5 h-5 rounded-full flex items-center justify-center animate-pulse">
          {unreadCount > 9 ? '9+' : unreadCount}
        </span>
      )}
    </Link>
  )
}
