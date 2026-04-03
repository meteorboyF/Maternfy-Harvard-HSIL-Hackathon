const { auth } = require('../config/firebase')

async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' })
  }

  const idToken = authHeader.split('Bearer ')[1]
  try {
    const decoded = await auth.verifyIdToken(idToken)
    req.user = decoded
    next()
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' })
  }
}

function requireRole(role) {
  return (req, res, next) => {
    const userRole = req.user?.role || req.user?.['https://maternify.app/role']
    if (userRole !== role) {
      return res.status(403).json({ error: `Requires ${role} role` })
    }
    next()
  }
}

module.exports = { verifyFirebaseToken, requireRole }
