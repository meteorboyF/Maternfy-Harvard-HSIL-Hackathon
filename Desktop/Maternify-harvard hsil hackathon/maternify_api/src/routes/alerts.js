const express = require('express')
const router = express.Router()
const { verifyFirebaseToken, requireRole } = require('../middleware/auth')
const alertsController = require('../controllers/alertsController')

router.get('/', verifyFirebaseToken, requireRole('provider'), alertsController.listAlerts)
router.patch('/:id/read', verifyFirebaseToken, alertsController.markRead)

module.exports = router
