const express = require('express')
const router = express.Router()
const { verifyFirebaseToken } = require('../middleware/auth')
const triageController = require('../controllers/triageController')

// POST /api/triage — main triage endpoint (F5)
router.post('/', verifyFirebaseToken, triageController.createTriageEvent)

// POST /api/triage/voice — transcribe audio then triage (F11)
router.post('/voice', verifyFirebaseToken, triageController.triageFromVoice)

// GET /api/triage/:patientId — history
router.get('/:patientId', verifyFirebaseToken, triageController.getTriageHistory)

module.exports = router
