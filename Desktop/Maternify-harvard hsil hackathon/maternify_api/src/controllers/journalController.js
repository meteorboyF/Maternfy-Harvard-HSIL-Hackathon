const { analyseJournalEntry, getJournalHistory } = require('../services/journalService')

/** POST /api/journal  — analyse + persist entry */
async function createEntry(req, res, next) {
  try {
    const { patient_id, entry_text, lang } = req.body
    if (!patient_id || !entry_text?.trim()) {
      return res.status(400).json({ error: 'patient_id and entry_text are required' })
    }
    const result = await analyseJournalEntry(patient_id, entry_text.trim(), lang || 'bn')
    res.json(result)
  } catch (err) {
    next(err)
  }
}

/** GET /api/journal/:patientId — fetch history */
async function getHistory(req, res, next) {
  try {
    const { patientId } = req.params
    const limit = Math.min(parseInt(req.query.limit) || 20, 50)
    const entries = await getJournalHistory(patientId, limit)
    res.json(entries)
  } catch (err) {
    next(err)
  }
}

module.exports = { createEntry, getHistory }
