'use client'

import { useState } from 'react'

interface Props {
  patientId: string
  patientName: string
}

export function AiSummaryCard({ patientId, patientName }: Props) {
  const [summary, setSummary] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const generate = async () => {
    setLoading(true)
    try {
      const res = await fetch(`/api/patients/${patientId}/summary`)
      const data = await res.json()
      setSummary(data.summary)
    } catch {
      setSummary('Failed to generate summary. Check API connection.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="bg-white rounded-xl border p-4">
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-sm font-semibold text-gray-700">AI Clinical Summary</h2>
        <span className="text-xs text-pink-500 font-medium">claude-sonnet-4-6</span>
      </div>

      {summary ? (
        <p className="text-sm text-gray-700 leading-relaxed">{summary}</p>
      ) : (
        <div className="text-center py-4">
          <p className="text-xs text-gray-400 mb-3">
            Generates a clinical summary using recent vitals, triage history, and risk score.
          </p>
          <button
            onClick={generate}
            disabled={loading}
            className="bg-pink-600 text-white text-sm px-4 py-2 rounded-lg hover:bg-pink-700 disabled:opacity-50 transition-colors"
          >
            {loading ? 'Generating...' : '✨ Generate Summary'}
          </button>
        </div>
      )}
    </div>
  )
}
