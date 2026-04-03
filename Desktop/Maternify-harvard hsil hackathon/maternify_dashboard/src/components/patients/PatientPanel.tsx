'use client'

import { useState } from 'react'
import Link from 'next/link'
import type { Patient, TriageTier } from '@/types'

const TIER_STYLES: Record<TriageTier, { badge: string; row: string; dot: string }> = {
  red:    { badge: 'bg-red-100 text-red-700 border border-red-300',    row: 'border-l-4 border-red-500 bg-red-50/40',    dot: 'bg-red-500 animate-pulse' },
  yellow: { badge: 'bg-yellow-100 text-yellow-700 border border-yellow-300', row: 'border-l-4 border-yellow-400 bg-yellow-50/40', dot: 'bg-yellow-400' },
  green:  { badge: 'bg-green-100 text-green-700 border border-green-300',  row: 'border-l-4 border-green-400',           dot: 'bg-green-500' },
}

const TIER_ORDER: Record<TriageTier, number> = { red: 0, yellow: 1, green: 2 }

interface Props {
  patients: Patient[]
  isLoading?: boolean
}

export function PatientPanel({ patients, isLoading }: Props) {
  const [search, setSearch] = useState('')
  const [tierFilter, setTierFilter] = useState<TriageTier | 'all'>('all')

  const filtered = patients
    .filter((p) => {
      const matchName = p.name.toLowerCase().includes(search.toLowerCase())
      const matchTier = tierFilter === 'all' || p.risk_tier === tierFilter
      return matchName && matchTier
    })
    .sort((a, b) => TIER_ORDER[a.risk_tier ?? 'green'] - TIER_ORDER[b.risk_tier ?? 'green'])

  return (
    <div>
      {/* Filters */}
      <div className="flex gap-3 mb-4 flex-wrap">
        <input
          type="text"
          placeholder="Search patients..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm flex-1 min-w-48 focus:outline-none focus:ring-2 focus:ring-pink-400"
        />
        <div className="flex gap-2">
          {(['all', 'red', 'yellow', 'green'] as const).map((tier) => (
            <button
              key={tier}
              onClick={() => setTierFilter(tier)}
              className={`px-3 py-2 rounded-lg text-xs font-semibold capitalize transition-colors ${
                tierFilter === tier
                  ? 'bg-pink-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {tier === 'all' ? 'All' : `🔴🟡🟢`.charAt(['red','yellow','green'].indexOf(tier)) + ' ' + tier}
            </button>
          ))}
        </div>
      </div>

      {/* Count summary */}
      <div className="flex gap-4 mb-4 text-sm">
        {(['red', 'yellow', 'green'] as TriageTier[]).map((tier) => {
          const count = patients.filter((p) => p.risk_tier === tier).length
          const s = TIER_STYLES[tier]
          return (
            <span key={tier} className={`px-2 py-1 rounded-full text-xs font-bold ${s.badge}`}>
              {count} {tier}
            </span>
          )
        })}
      </div>

      {/* Patient rows */}
      {isLoading ? (
        <div className="space-y-2">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-16 bg-gray-100 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-12 text-gray-400">No patients match filters</div>
      ) : (
        <div className="space-y-2">
          {filtered.map((patient) => {
            const tier = patient.risk_tier ?? 'green'
            const s = TIER_STYLES[tier]
            return (
              <Link
                key={patient.id}
                href={`/patients/${patient.id}`}
                className={`block rounded-lg p-4 hover:shadow-md transition-shadow ${s.row}`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`w-3 h-3 rounded-full ${s.dot}`} />
                    <div>
                      <p className="font-semibold text-gray-900">{patient.name}</p>
                      <p className="text-xs text-gray-500">
                        {patient.weeks_gestation}w · G{patient.gravida}P{patient.parity} · {patient.blood_type}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    {patient.latest_systolic && (
                      <span className={`text-sm font-mono font-bold ${
                        (patient.latest_systolic ?? 0) >= 140 ? 'text-red-600' : 'text-gray-600'
                      }`}>
                        {patient.latest_systolic}/{patient.latest_diastolic}
                      </span>
                    )}
                    <span className={`text-xs px-2 py-1 rounded-full font-semibold capitalize ${s.badge}`}>
                      {tier}
                    </span>
                    <span className="text-gray-400 text-lg">›</span>
                  </div>
                </div>
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}
