const supabase = require('../config/supabase')
const axios = require('axios')

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000'

exports.logVitals = async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('vitals_logs')
      .insert(req.body)
      .select()
      .single()

    if (error) throw error

    // Fire-and-forget anomaly check to ML service
    axios.post(`${ML_SERVICE_URL}/vitals-anomaly`, {
      patient_id: data.patient_id,
      latest_vitals: data,
    }).catch((err) => console.error('ML anomaly check failed:', err.message))

    res.status(201).json(data)
  } catch (err) {
    next(err)
  }
}

exports.getVitals = async (req, res, next) => {
  try {
    const { days = 14 } = req.query
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString()

    const { data, error } = await supabase
      .from('vitals_logs')
      .select('*')
      .eq('patient_id', req.params.patientId)
      .gte('logged_at', since)
      .order('logged_at', { ascending: true })

    if (error) throw error
    res.json(data)
  } catch (err) {
    next(err)
  }
}
