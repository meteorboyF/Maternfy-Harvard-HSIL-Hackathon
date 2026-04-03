const Joi = require('joi')
const { runTriage } = require('../services/triageService')
const supabase = require('../config/supabase')

const triageSchema = Joi.object({
  patient_id: Joi.string().uuid().required(),
  input_text: Joi.string().min(3).max(2000).required(),
  input_lang: Joi.string().valid('bn', 'en').default('bn'),
  ml_risk_tier: Joi.string().valid('green', 'yellow', 'red').default('green'),
})

exports.createTriageEvent = async (req, res, next) => {
  try {
    const { error, value } = triageSchema.validate(req.body)
    if (error) return res.status(400).json({ error: error.details[0].message })

    const triageEvent = await runTriage(
      value.patient_id,
      value.input_text,
      value.input_lang,
      value.ml_risk_tier
    )

    res.status(201).json(triageEvent)
  } catch (err) {
    next(err)
  }
}

exports.triageFromVoice = async (req, res, next) => {
  try {
    // F11 will implement: Whisper transcription → createTriageEvent
    res.status(501).json({ message: 'Voice triage — implemented in F11' })
  } catch (err) {
    next(err)
  }
}

exports.getTriageHistory = async (req, res, next) => {
  try {
    const { patientId } = req.params
    const { data, error } = await supabase
      .from('triage_events')
      .select('*')
      .eq('patient_id', patientId)
      .order('created_at', { ascending: false })
      .limit(20)

    if (error) throw error
    res.json(data)
  } catch (err) {
    next(err)
  }
}
