const express = require('express')
const router = express.Router()
const { verifyFirebaseToken } = require('../middleware/auth')
const vitalsController = require('../controllers/vitalsController')

router.post('/', verifyFirebaseToken, vitalsController.logVitals)
router.get('/:patientId', verifyFirebaseToken, vitalsController.getVitals)

module.exports = router
