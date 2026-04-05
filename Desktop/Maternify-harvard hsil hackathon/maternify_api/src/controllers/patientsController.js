const supabase = require('../config/supabase')

exports.listPatients = async (req, res, next) => {
  try {
    const { provider_id } = req.query
    let query = supabase.from('patients').select('*').order('created_at', { ascending: false })
    if (provider_id) query = query.eq('provider_id', provider_id)

    const { data, error } = await query
    if (error) throw error
    res.json(data)
  } catch (err) {
    next(err)
  }
}

exports.getPatient = async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('patients')
      .select('*')
      .eq('id', req.params.id)
      .single()

    if (error) throw error
    if (!data) return res.status(404).json({ error: 'Patient not found' })
    res.json(data)
  } catch (err) {
    next(err)
  }
}

/**
 * GET /api/patients/:id/risk-score
 * Mock risk score based on latest BP.
 * Replace with real XGBoost call when models are trained.
 */
exports.getRiskScore = async (req, res, next) => {
  try {
    const { data: vitals } = await supabase
      .from('vitals_logs')
      .select('systolic_bp, diastolic_bp, weight_kg, blood_glucose, kick_count, logged_at')
      .eq('patient_id', req.params.id)
      .order('logged_at', { ascending: false })
      .limit(1)
      .single()

    if (!vitals) return res.json({ risk_tier: 'green', risk_score: 0.1, shap_values: {} })

    const systolic = vitals.systolic_bp
    let tier, score
    if (systolic >= 140) {
      tier = 'red'; score = 0.85
    } else if (systolic >= 130) {
      tier = 'yellow'; score = 0.55
    } else {
      tier = 'green'; score = 0.15
    }

    // Hardcoded SHAP values for demo visualization
    res.json({
      risk_tier: tier,
      risk_score: score,
      shap_values: {
        systolic_bp: +(score * 0.48).toFixed(2),
        weight_change_7d: +(score * 0.28).toFixed(2),
        blood_glucose: +(score * 0.14).toFixed(2),
        kick_count: +(score * 0.10).toFixed(2),
      },
      latest_vitals: vitals,
      _mock: true,
    })
  } catch (err) {
    next(err)
  }
}

/**
 * GET /api/patients/:id/summary
 * Mock AI summary. Replace with Claude API call.
 */
exports.getPatientSummary = async (req, res, next) => {
  try {
    const [patientRes, vitalsRes, triageRes] = await Promise.all([
      supabase.from('patients').select('*').eq('id', req.params.id).single(),
      supabase.from('vitals_logs').select('*').eq('patient_id', req.params.id)
        .order('logged_at', { ascending: false }).limit(14),
      supabase.from('triage_events').select('triage_tier, created_at').eq('patient_id', req.params.id)
        .order('created_at', { ascending: false }).limit(5),
    ])

    const patient = patientRes.data
    const vitals = vitalsRes.data || []
    const triage = triageRes.data || []

    if (!patient) return res.status(404).json({ error: 'Patient not found' })

    // Build summary from real data
    const latestBp = vitals[0] ? `${vitals[0].systolic_bp}/${vitals[0].diastolic_bp}` : 'N/A'
    const oldestBp = vitals[vitals.length - 1]
    const bpChange = (vitals[0] && oldestBp)
      ? vitals[0].systolic_bp - oldestBp.systolic_bp
      : 0
    const weightChange = (vitals[0] && oldestBp)
      ? (vitals[0].weight_kg - oldestBp.weight_kg).toFixed(1)
      : 0
    const redCount = triage.filter(t => t.triage_tier === 'red').length
    const yellowCount = triage.filter(t => t.triage_tier === 'yellow').length

    const summary = `গত ${vitals.length} দিনে: গড় BP ${latestBp} (↑${bpChange} mmHg), ওজন বৃদ্ধি ${weightChange} কেজি। ` +
      `${redCount > 0 ? redCount + 'টি RED' : ''}${yellowCount > 0 ? (redCount ? ' ও ' : '') + yellowCount + 'টি YELLOW' : ''} triage ইভেন্ট।` +
      (bpChange > 10 ? ' BP পর্যবেক্ষণ জরুরি।' : ' স্বাভাবিক পরিসরে আছেন।')

    res.json({
      summary,
      patient_name: patient.name,
      weeks_gestation: patient.weeks_gestation,
      vitals_count: vitals.length,
      triage_count: triage.length,
      _mock: true,
    })
  } catch (err) {
    next(err)
  }
}

exports.createPatient = async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('patients')
      .insert(req.body)
      .select()
      .single()

    if (error) throw error
    res.status(201).json(data)
  } catch (err) {
    next(err)
  }
}

exports.updatePatient = async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('patients')
      .update(req.body)
      .eq('id', req.params.id)
      .select()
      .single()

    if (error) throw error
    res.json(data)
  } catch (err) {
    next(err)
  }
}
