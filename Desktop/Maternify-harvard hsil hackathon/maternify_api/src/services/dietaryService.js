/**
 * Maternify Dietary Advisor Service — F18
 * Knowledge-augmented generation: patient vitals context + curated
 * Bangladeshi maternal nutrition knowledge base → Claude → structured advice.
 */

const Anthropic = require('@anthropic-ai/sdk')
const supabase = require('../config/supabase')

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

// ── RAG knowledge base (embedded) ────────────────────────────────────────────

const NUTRITION_KB = `
## Bangladeshi Maternal Nutrition Knowledge Base

### High-priority foods by nutrient (Bangladesh context)
IRON (prevents anaemia):
  - লাল শাক (red amaranth) — best local iron source
  - পালং শাক (spinach), কচু শাক (taro leaves)
  - ডাল/মসুর ডাল (red lentils) — cheap, widely available
  - কলিজা (liver) — 1–2×/week maximum
  - ইলিশ / রুই / কাতলা মাছ (hilsa, rui, catla) — iron + omega-3
  - গুড় (jaggery/molasses) — traditional iron source
  Tip: pair with vitamin C (lemon, amla) to double absorption.

CALCIUM (bone & teeth):
  - দুধ (milk) 2 glasses/day
  - দই (yogurt)
  - মোলা মাছ / কাচকি মাছ (small whole fish) — 200 mg Ca per serving
  - তিল (sesame seeds)
  - কাঁঠালের বিচি (jackfruit seeds, boiled)

FOLIC ACID (neural tube, especially weeks 4–12):
  - সবুজ শাকসবজি (all dark leafy greens)
  - মুগ ডাল, মসুর ডাল (mung beans, lentils)
  - ডিম (eggs)

PROTEIN:
  - ডিম (eggs) — most complete protein
  - মাছ (fish) — preferred over red meat
  - ডাল (pulses) — daily staple
  - মুরগি (chicken)

OMEGA-3 / DHA (fetal brain):
  - ইলিশ মাছ (hilsa) — highest omega-3 among local fish
  - সার্ডিন, টুনা (canned, low-mercury)

VITAMIN A (≥ week 16):
  - মিষ্টি কুমড়া (sweet pumpkin/kabocha)
  - গাজর (carrot)
  - ডিমের কুসুম (egg yolk)

HYDRATION:
  - 8–10 glasses water/day
  - ডাবের পানি (coconut water) — electrolytes + hydration
  - ডালের পানি (lentil water), ভাতের মাড় (rice water) for nausea

### Trimester-specific guidance
FIRST (weeks 1–12) — nausea management & folate loading:
  - Small, frequent meals (5–6×/day) instead of 3 large
  - আদা চা (ginger tea) for morning sickness
  - লেবু পানি (lemon water) for nausea
  - ভাতের মাড় (rice starch water) — soothing
  - Avoid spicy/greasy foods if nauseous
  - Folic acid priority: leafy greens, lentils, eggs every day

SECOND (weeks 13–27) — growth surge, iron & calcium focus:
  - Increase total calories by ~300 kcal/day (an extra cup of rice + dal)
  - Iron-rich foods every day (lal shak + lentils + small fish)
  - 2 servings dairy/day for calcium
  - প্রতিদিন একটি ডিম (one egg daily)
  - Vitamin D: 15 min sunlight exposure

THIRD (weeks 28–40) — energy, omega-3, avoid constipation:
  - High-fibre foods: শাক, কাঁচা পেঁপে (ripe papaya only), ওটস
  - Small meals more often (stomach compressed)
  - ইলিশ 2–3×/week for DHA (fetal brain development)
  - Reduce salt if BP is elevated
  - Avoid gas-producing foods: পেঁয়াজ কাঁচা, বাঁধাকপি in large amounts

### Foods to avoid during pregnancy (Bangladesh-specific)
ABSOLUTE AVOID:
  - কাঁচা পেঁপে (raw/unripe papaya) — contains papain, can trigger contractions
  - কাঁচা আনারস (raw pineapple core) — bromelain risk
  - অতিরিক্ত চা/কফি (excessive tea/coffee — > 200 mg caffeine)
  - কাঁচা মাংস / আধা-সিদ্ধ ডিম (raw meat / undercooked eggs)
  - কাঁচা মাছ / শুটকি অতিরিক্ত (raw or excessive dried fish — high sodium)
  - অ্যালকোহল (alcohol — absolutely zero)

LIMIT:
  - কলিজা (liver) — max 1–2×/week (excess vitamin A teratogenic)
  - পারদ-সমৃদ্ধ মাছ (high-mercury fish: shark, king mackerel, swordfish)
  - অতিরিক্ত লবণ (excess salt) — especially if BP ≥ 130/80
  - মিষ্টি / ভাজাপোড়া (sweets / fried foods) — especially if blood glucose is elevated

### Gestational diabetes dietary rules (if blood_glucose > 7.0 mmol/L)
  - Replace white rice with brown rice or mix 50/50
  - Smaller rice portions — fill half plate with vegetables
  - Avoid মিষ্টি, রসগোল্লা, halwa, condensed milk
  - Choose low-GI: oats, whole wheat chapati, sweet potato in moderation
  - Eat fruit WITH protein/fat (e.g. apple + peanut butter) to blunt glucose spike
  - Never skip meals — 3 main + 2–3 snacks

### Weight gain targets (Bangladesh BMI norms)
  - Underweight (BMI < 18.5): 12.5–18 kg total
  - Normal (18.5–24.9): 11.5–16 kg total
  - Overweight (25–29.9): 7–11.5 kg total
  - Obese (≥ 30): 5–9 kg total
`

// ── System prompt template ────────────────────────────────────────────────────

const SYSTEM_PROMPT = `You are Maternify's dietary advisor for pregnant women in Bangladesh.

Patient context:
- Gestational week: {{weeks_gestation}}
- Latest vitals: {{vitals_json}}
- Trimester: {{trimester}}

Knowledge base:
${NUTRITION_KB}

Respond ONLY with valid JSON (no markdown fences, no explanation):
{
  "advice_bangla": "<main advice in Bengali Unicode, Grade 6 reading level, 2–4 short sentences>",
  "advice_english": "<same advice in English, 2–3 sentences>",
  "recommended_foods": ["<Bangla food name>", ...],
  "foods_to_avoid": ["<Bangla food name>", ...],
  "trimester_tip": "<one specific tip for this trimester in Bangla>"
}

Rules:
- Never prescribe medications or supplements by brand name.
- If blood_glucose > 7.0 mmol/L, apply gestational diabetes rules.
- If systolic_bp >= 140 or diastolic_bp >= 90, recommend low-salt foods.
- Recommend locally available Bangladeshi foods only.
- advice_bangla and trimester_tip MUST be in Bengali Unicode script.
- recommended_foods and foods_to_avoid: 3–5 items each.`

// ── Main function ─────────────────────────────────────────────────────────────

/**
 * @param {string} patientId
 * @param {string} query - user's food question (Bangla or English)
 * @returns {object} { advice_bangla, advice_english, recommended_foods, foods_to_avoid, trimester_tip }
 */
async function getDietaryAdvice(patientId, query) {
  // 1. Fetch patient + latest vitals
  const [patientRes, vitalsRes] = await Promise.all([
    supabase.from('patients').select('*').eq('id', patientId).single(),
    supabase
      .from('vitals_logs')
      .select('*')
      .eq('patient_id', patientId)
      .order('logged_at', { ascending: false })
      .limit(3),
  ])

  if (patientRes.error) throw new Error(`Patient not found: ${patientRes.error.message}`)
  const patient = patientRes.data
  const vitals = vitalsRes.data || []

  // 2. Build concise vitals summary
  const latestVitals = vitals[0] || null
  const vitalsSummary = latestVitals
    ? {
        bp: `${latestVitals.systolic_bp}/${latestVitals.diastolic_bp} mmHg`,
        weight_kg: latestVitals.weight_kg,
        blood_glucose_mmol: latestVitals.blood_glucose,
        logged: latestVitals.logged_at.slice(0, 10),
      }
    : 'No vitals logged yet'

  const week = patient.weeks_gestation
  const trimester = week <= 12 ? '1st (weeks 1–12)' : week <= 27 ? '2nd (weeks 13–27)' : '3rd (weeks 28–40)'

  // 3. Build system prompt
  const systemPrompt = SYSTEM_PROMPT
    .replace('{{weeks_gestation}}', week)
    .replace('{{vitals_json}}', JSON.stringify(vitalsSummary))
    .replace('{{trimester}}', trimester)

  // 4. Call Claude
  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 600,
    system: systemPrompt,
    messages: [{ role: 'user', content: query }],
  })

  // 5. Parse JSON
  const raw = message.content[0].text.trim()
  let parsed
  try {
    const jsonStr = raw.replace(/^```json?\s*/i, '').replace(/```\s*$/i, '').trim()
    parsed = JSON.parse(jsonStr)
  } catch {
    throw new Error(`Claude returned non-JSON: ${raw.slice(0, 200)}`)
  }

  return {
    advice_bangla: parsed.advice_bangla || '',
    advice_english: parsed.advice_english || '',
    recommended_foods: Array.isArray(parsed.recommended_foods) ? parsed.recommended_foods : [],
    foods_to_avoid: Array.isArray(parsed.foods_to_avoid) ? parsed.foods_to_avoid : [],
    trimester_tip: parsed.trimester_tip || '',
    weeks_gestation: week,
    trimester,
  }
}

module.exports = { getDietaryAdvice }
