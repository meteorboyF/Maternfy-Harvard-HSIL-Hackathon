'use client'

import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  ReferenceLine, ResponsiveContainer, Legend,
} from 'recharts'
import { format } from 'date-fns'
import type { VitalsLog } from '@/types'

interface Props { vitals: VitalsLog[] }

export function VitalsChart({ vitals }: Props) {
  if (vitals.length === 0) {
    return <div className="h-40 flex items-center justify-center text-gray-400 text-sm">No vitals recorded</div>
  }

  const data = vitals.map((v) => ({
    date: format(new Date(v.logged_at), 'MM/dd'),
    systolic: v.systolic_bp,
    diastolic: v.diastolic_bp,
    glucose: v.blood_glucose,
  }))

  return (
    <ResponsiveContainer width="100%" height={200}>
      <LineChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
        <XAxis dataKey="date" tick={{ fontSize: 11 }} />
        <YAxis tick={{ fontSize: 11 }} domain={[60, 'auto']} />
        <Tooltip
          contentStyle={{ fontSize: 12, borderRadius: 8 }}
          formatter={(val: number, name: string) => [
            `${val}${name === 'glucose' ? ' mmol/L' : ' mmHg'}`,
            name === 'systolic' ? 'Systolic' : name === 'diastolic' ? 'Diastolic' : 'Glucose',
          ]}
        />
        <Legend wrapperStyle={{ fontSize: 12 }} />
        {/* Danger thresholds */}
        <ReferenceLine y={140} stroke="#ef4444" strokeDasharray="4 4" label={{ value: '140', fontSize: 10, fill: '#ef4444' }} />
        <ReferenceLine y={90}  stroke="#f97316" strokeDasharray="4 4" label={{ value: '90',  fontSize: 10, fill: '#f97316' }} />
        <Line type="monotone" dataKey="systolic"  stroke="#e91e8c" strokeWidth={2} dot={false} name="systolic" />
        <Line type="monotone" dataKey="diastolic" stroke="#9c27b0" strokeWidth={2} dot={false} name="diastolic" />
      </LineChart>
    </ResponsiveContainer>
  )
}
