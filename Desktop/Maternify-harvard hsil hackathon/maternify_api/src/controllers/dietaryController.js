const { getDietaryAdvice } = require('../services/dietaryService')

/**
 * POST /api/dietary
 * Body: { patient_id, query }
 */
async function getDietary(req, res, next) {
  try {
    const { patient_id, query } = req.body
    if (!patient_id || !query?.trim()) {
      return res.status(400).json({ error: 'patient_id and query are required' })
    }

    const result = await getDietaryAdvice(patient_id, query.trim())
    res.json(result)
  } catch (err) {
    next(err)
  }
}

module.exports = { getDietary }
