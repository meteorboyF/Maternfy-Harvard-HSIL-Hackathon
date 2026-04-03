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
