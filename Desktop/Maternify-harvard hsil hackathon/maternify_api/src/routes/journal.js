const express = require('express')
const router = express.Router()
const { verifyFirebaseToken } = require('../middleware/auth')
const { createEntry, getHistory } = require('../controllers/journalController')

router.post('/', verifyFirebaseToken, createEntry)
router.get('/:patientId', verifyFirebaseToken, getHistory)

module.exports = router
