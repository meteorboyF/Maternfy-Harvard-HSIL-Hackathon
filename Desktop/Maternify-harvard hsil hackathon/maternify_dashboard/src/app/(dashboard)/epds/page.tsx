'use client'

import { useState } from 'react'
import { supabase } from '@/lib/supabase'

const EPDS_QUESTIONS = [
  { q: 'I have been able to laugh and see the funny side of things.', opts: ['As much as I always could', 'Not quite so much now', 'Definitely not so much now', 'Not at all'], scores: [0,1,2,3] },
  { q: 'I have looked forward with enjoyment to things.', opts: ['As much as I ever did', 'Rather less than I used to', 'Definitely less than I used to', 'Hardly at all'], scores: [0,1,2,3] },
  { q: 'I have blamed myself unnecessarily when things went wrong.', opts: ['No, never', 'Not very often', 'Yes, some of the time', 'Yes, most of the time'], scores: [0,1,2,3] },
  { q: 'I have been anxious or worried for no good reason.', opts: ['No, not at all', 'Hardly ever', 'Yes, sometimes', 'Yes, very often'], scores: [0,1,2,3] },
  { q: 'I have felt scared or panicky for no very good reason.', opts: ['No, not at all', 'No, not much', 'Yes, sometimes', 'Yes, quite a lot'], scores: [0,1,2,3] },
  { q: 'Things have been getting on top of me.', opts: ['No, I have been coping as well as ever', 'No, most of the time I have coped quite well', 'Yes, sometimes I haven\'t been coping as well as usual', 'Yes, most of the time I haven\'t been able to cope at all'], scores: [0,1,2,3] },
  { q: 'I have been so unhappy that I have had difficulty sleeping.', opts: ['No, not at all', 'Not very often', 'Yes, sometimes', 'Yes, most of the time'], scores: [0,1,2,3] },
  { q: 'I have felt sad or miserable.', opts: ['No, not at all', 'Not very often', 'Yes, quite often', 'Yes, most of the time'], scores: [0,1,2,3] },
  { q: 'I have been so unhappy that I have been crying.', opts: ['No, never', 'Only occasionally', 'Yes, quite often', 'Yes, most of the time'], scores: [0,1,2,3] },
  { q: 'The thought of harming myself has occurred to me.', opts: ['Never', 'Hardly ever', 'Sometimes', 'Yes, quite often'], scores: [0,1,2,3] },
]

export default function EpdsPage() {
  const [patientId, setPatientId] = useState('')
  const [answers, setAnswers] = useState<number[]>(Array(10).fill(-1))
  const [submitted, setSubmitted] = useState(false)
  const [score, setScore] = useState(0)
  const [saving, setSaving] = useState(false)

  const totalScore = answers.reduce((s, a, i) => s + (a >= 0 ? EPDS_QUESTIONS[i].scores[a] : 0), 0)
  const allAnswered = answers.every((a) => a >= 0)
  const flagged = totalScore >= 12

  const handleSubmit = async () => {
    if (!patientId || !allAnswered) return
    setSaving(true)
    try {
      await supabase.from('epds_scores').insert({
        patient_id: patientId,
        score: totalScore,
        flagged,
        answers: answers.map((a, i) => ({ q: i + 1, selected: a, score: EPDS_QUESTIONS[i].scores[a] })),
      })

      if (flagged) {
        await supabase.from('alerts').insert({
          patient_id: patientId,
          provider_id: 'demo-provider-uid-001',
          alert_type: 'epds_flagged',
          message: `EPDS score ${totalScore}/30 — PPD screening flagged. Immediate follow-up recommended.`,
          read: false,
        })
      }

      setScore(totalScore)
      setSubmitted(true)
    } finally {
      setSaving(false)
    }
  }

  const reset = () => {
    setAnswers(Array(10).fill(-1))
    setSubmitted(false)
    setPatientId('')
  }

  if (submitted) {
    return (
      <div className="p-6 max-w-2xl mx-auto">
        <div className={`rounded-2xl p-8 text-center ${flagged ? 'bg-red-50 border-2 border-red-300' : 'bg-green-50 border-2 border-green-300'}`}>
          <p className="text-5xl mb-4">{flagged ? '⚠️' : '✅'}</p>
          <h2 className={`text-3xl font-bold mb-2 ${flagged ? 'text-red-700' : 'text-green-700'}`}>
            Score: {score} / 30
          </h2>
          <p className={`text-lg font-medium ${flagged ? 'text-red-600' : 'text-green-600'}`}>
            {flagged
              ? 'Score ≥ 12 — Possible depression. Provider alerted.'
              : 'Score < 12 — Low PPD risk at this time.'}
          </p>
          {flagged && (
            <p className="text-sm text-red-500 mt-3">
              An alert has been sent to the provider dashboard.
            </p>
          )}
          <button onClick={reset} className="mt-6 bg-pink-600 text-white px-6 py-2 rounded-lg hover:bg-pink-700">
            New Screening
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 mb-1">EPDS Screening</h1>
      <p className="text-sm text-gray-500 mb-6">Edinburgh Postnatal Depression Scale — 10 questions, auto-scored</p>

      {/* Patient selector */}
      <div className="mb-6">
        <label className="block text-sm font-medium text-gray-700 mb-1">Patient ID</label>
        <input
          type="text"
          value={patientId}
          onChange={(e) => setPatientId(e.target.value)}
          placeholder="Paste patient UUID..."
          className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-pink-400"
        />
      </div>

      {/* Questions */}
      <div className="space-y-6">
        {EPDS_QUESTIONS.map((q, qi) => (
          <div key={qi} className={`bg-white rounded-xl border p-4 ${answers[qi] >= 0 ? 'border-pink-200' : ''}`}>
            <p className="text-sm font-medium text-gray-800 mb-3">
              <span className="text-pink-500 font-bold">{qi + 1}.</span> {q.q}
            </p>
            <div className="space-y-2">
              {q.opts.map((opt, oi) => (
                <label key={oi} className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="radio"
                    name={`q${qi}`}
                    checked={answers[qi] === oi}
                    onChange={() => setAnswers((prev) => { const n = [...prev]; n[qi] = oi; return n })}
                    className="accent-pink-600"
                  />
                  <span className="text-sm text-gray-700">{opt}</span>
                </label>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Live score */}
      <div className="sticky bottom-6 mt-6 bg-white rounded-xl border shadow-lg p-4 flex items-center justify-between">
        <div>
          <p className="text-xs text-gray-500">Current score</p>
          <p className={`text-2xl font-bold ${totalScore >= 12 ? 'text-red-600' : 'text-gray-800'}`}>
            {allAnswered ? totalScore : answers.filter((a) => a >= 0).length + ' / 10 answered'}
          </p>
        </div>
        <button
          onClick={handleSubmit}
          disabled={!allAnswered || !patientId || saving}
          className="bg-pink-600 text-white px-6 py-3 rounded-lg font-semibold disabled:opacity-40 hover:bg-pink-700 transition-colors"
        >
          {saving ? 'Saving...' : 'Submit Score'}
        </button>
      </div>
    </div>
  )
}
