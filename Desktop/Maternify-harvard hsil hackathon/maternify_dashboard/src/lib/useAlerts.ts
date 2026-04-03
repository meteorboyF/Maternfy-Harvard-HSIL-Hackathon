'use client'

import { useEffect, useState } from 'react'
import { collection, onSnapshot, query, where, orderBy, Timestamp } from 'firebase/firestore'
import { firestore } from './firebase'
import type { Alert } from '@/types'

/**
 * F8 — Real-time Firestore alert listener.
 * Returns unread alerts for the given provider, updating in <2s when a
 * Red triage event fires from the Node API.
 */
export function useRealtimeAlerts(providerId: string | null) {
  const [alerts, setAlerts] = useState<Alert[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!providerId) {
      setLoading(false)
      return
    }

    const q = query(
      collection(firestore, 'alerts'),
      where('provider_id', '==', providerId),
      where('read', '==', false),
      orderBy('created_at', 'desc')
    )

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const docs = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Alert[]

        setAlerts(docs)
        setUnreadCount(docs.length)
        setLoading(false)

        // Play notification sound on new alert (non-first load)
        if (!loading && snapshot.docChanges().some((c) => c.type === 'added')) {
          playAlertSound()
        }
      },
      (error) => {
        console.error('Firestore alert listener error:', error)
        setLoading(false)
      }
    )

    return () => unsubscribe()
  }, [providerId])

  return { alerts, unreadCount, loading }
}

function playAlertSound() {
  try {
    const ctx = new AudioContext()
    const osc = ctx.createOscillator()
    const gain = ctx.createGain()
    osc.connect(gain)
    gain.connect(ctx.destination)
    osc.frequency.value = 880
    gain.gain.setValueAtTime(0.3, ctx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4)
    osc.start(ctx.currentTime)
    osc.stop(ctx.currentTime + 0.4)
  } catch {
    // AudioContext not available (SSR or blocked)
  }
}
