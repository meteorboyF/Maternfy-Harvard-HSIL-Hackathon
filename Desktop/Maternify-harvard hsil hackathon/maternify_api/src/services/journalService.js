/**
 * Maternify Journal Service — F19
 * Mother writes a free-form mood entry → Claude NLP analyses sentiment,
 * returns a supportive response in Bangla + English + structured mood data.
 * Entry + analysis are persisted in Supabase messages table.
 */

const Anthropic = require('@anthropic-ai/sdk')
const supabase = require('../config/supabase')

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

const SYSTEM_PROMPT = `You are the compassionate mood journal companion for Maternify,
a maternal health app for pregnant and postpartum women in Bangladesh.

Analyse the journal entry and respond ONLY with valid JSON (no markdown, no explanation):
{
  "mood_score": <integer 1–10, where 1=very distressed, 10=very well>,
  "mood_label": "<one of: joyful|content|anxious|sad|overwhelmed|fearful|angry|hopeful>",
  "mood_emoji": "<single emoji that best represents the mood>",
  "sentiment": "<positive|neutral|negative>",
  "key_themes": ["<theme>", ...],
  "response_bangla": "<warm, supportive 2–3 sentence response in Bengali Unicode, Grade 6 reading level>",
  "response_english": "<same warm response in English>",
  "epds_concern": <true if entry contains signs of depression, hopelessness, self-harm ideation, or persistent sadness — false otherwise>,
  "coping_tip_bangla": "<one practical, culturally appropriate self-care tip in Bengali Unicode>"
}

Rules:
- Never be dismissive. Always validate the mother's feelings first.
- response_bangla and coping_tip_bangla MUST be in Bengali Unicode script.
- If mood_score <= 4 or epds_concern=true, gently recommend talking to a doctor.
- key_themes: 2–4 short English phrases (e.g. "nausea", "sleep issues", "family support").
- mood_score must reflect the overall emotional tone, not just one sentence.`

/**
 * Analyse a journal entry and persist it.
 * @param {string} patientId
 * @param {string} entryText
 * @param {string} [lang='bn']  — 'bn' | 'en'
 * @returns {object} persisted record with Claude analysis fields
 */
async function analyseJournalEntry(patientId, entryText, lang = 'bn') {
  // 1. Call Claude
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 512,
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content: entryText }],
  })

  const raw = message.content[0].text.trim()
  let analysis
  try {
    const jsonStr = raw.replace(/^```json?\s*/i, '').replace(/```\s*$/i, '').trim()
    analysis = JSON.parse(jsonStr)
  } catch {
    throw new Error(`Claude returned non-JSON: ${raw.slice(0, 200)}`)
  }

  // 2. Persist to Supabase messages table
  //    content stores JSON so we can retrieve the full analysis later
  const payload = {
    entry_text: entryText,
    lang,
    mood_score: analysis.mood_score,
    mood_label: analysis.mood_label,
    mood_emoji: analysis.mood_emoji,
    sentiment: analysis.sentiment,
    key_themes: analysis.key_themes,
    response_bangla: analysis.response_bangla,
    response_english: analysis.response_english,
    epds_concern: !!analysis.epds_concern,
    coping_tip_bangla: analysis.coping_tip_bangla,
  }

  const { data: saved, error } = await supabase
    .from('messages')
    .insert({
      sender_id: patientId,
      receiver_id: 'maternify-journal',
      content: JSON.stringify(payload),
    })
    .select()
    .single()

  if (error) throw new Error(`Failed to persist journal entry: ${error.message}`)

  return { id: saved.id, sent_at: saved.sent_at, ...payload }
}

/**
 * Fetch recent journal entries for a patient (newest first).
 * @param {string} patientId
 * @param {number} [limit=20]
 */
async function getJournalHistory(patientId, limit = 20) {
  const { data, error } = await supabase
    .from('messages')
    .select('id, content, sent_at')
    .eq('sender_id', patientId)
    .eq('receiver_id', 'maternify-journal')
    .order('sent_at', { ascending: false })
    .limit(limit)

  if (error) throw new Error(`Failed to fetch journal history: ${error.message}`)

  return (data || []).map((row) => {
    try {
      return { id: row.id, sent_at: row.sent_at, ...JSON.parse(row.content) }
    } catch {
      return { id: row.id, sent_at: row.sent_at, entry_text: row.content }
    }
  })
}

module.exports = { analyseJournalEntry, getJournalHistory }
