const supabase = require('../config/supabase')

exports.listAlerts = async (req, res, next) => {
  try {
    const { provider_id, unread_only } = req.query
    let query = supabase
      .from('alerts')
      .select('*, patients(name, weeks_gestation, blood_type)')
      .order('created_at', { ascending: false })

    if (provider_id) query = query.eq('provider_id', provider_id)
    if (unread_only === 'true') query = query.eq('read', false)

    const { data, error } = await query
    if (error) throw error
    res.json(data)
  } catch (err) {
    next(err)
  }
}

exports.markRead = async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('alerts')
      .update({ read: true })
      .eq('id', req.params.id)
      .select()
      .single()

    if (error) throw error
    res.json(data)
  } catch (err) {
    next(err)
  }
}
