const express = require('express')
const router = express.Router()
const { verifyFirebaseToken, requireRole } = require('../middleware/auth')
const patientsController = require('../controllers/patientsController')

router.get('/', verifyFirebaseToken, requireRole('provider'), patientsController.listPatients)
router.get('/:id', verifyFirebaseToken, patientsController.getPatient)
router.get('/:id/risk-score', verifyFirebaseToken, patientsController.getRiskScore)
router.get('/:id/summary', verifyFirebaseToken, patientsController.getPatientSummary)
router.post('/', verifyFirebaseToken, requireRole('provider'), patientsController.createPatient)
router.patch('/:id', verifyFirebaseToken, requireRole('provider'), patientsController.updatePatient)

module.exports = router
