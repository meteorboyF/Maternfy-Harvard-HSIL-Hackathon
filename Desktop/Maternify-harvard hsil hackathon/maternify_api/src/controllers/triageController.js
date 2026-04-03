// Triage controller — full Claude API integration built in F5
const supabase = require('../config/supabase')

exports.createTriageEvent = async (req, res, next) => {
  try {
    // F5 will implement: fetch vitals → build prompt → call Claude API → persist + alert pipeline
    res.status(501).json({ message: 'Triage endpoint — implemented in F5' })
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
