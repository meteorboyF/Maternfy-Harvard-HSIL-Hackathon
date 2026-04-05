/**
 * Mock triage service for demo / offline mode.
 * Used when ANTHROPIC_API_KEY is not set.
 * Replaces real Claude call with keyword matching.
 */

const path = require('path')
const fs = require('fs')

const MOCK_DATA_PATH = path.join(__dirname, '..', '..', '..', 'mock_data', 'triage_responses.json')

let _rules = null
let _default = null

function loadRules() {
  if (_rules) return
  const raw = JSON.parse(fs.readFileSync(MOCK_DATA_PATH, 'utf8'))
  _rules = raw.rules
  _default = raw.default
}

/**
 * Match input text against keyword rules.
 * Returns the first matching rule's response, or default.
 *
 * Priority: RED > YELLOW > GREEN (rules are ordered in JSON)
 */
function mockTriage(inputText) {
  loadRules()
  const lower = inputText.toLowerCase()

  // Collect all matches, then pick highest severity
  const matches = _rules.filter(rule =>
    rule.keywords.some(kw => lower.includes(kw.toLowerCase()))
  )

  if (matches.length === 0) return { ..._default }

  // Priority order
  const priority = { red: 3, yellow: 2, green: 1 }
  matches.sort((a, b) => (priority[b.triage_tier] || 0) - (priority[a.triage_tier] || 0))

  const best = matches[0]
  return {
    triage_tier: best.triage_tier,
    advice_bangla: best.advice_bangla,
    advice_english: best.advice_english,
    escalation_required: best.escalation_required,
    suggested_action: best.suggested_action,
  }
}

module.exports = { mockTriage }
