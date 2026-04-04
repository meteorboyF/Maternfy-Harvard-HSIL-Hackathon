const express = require('express')
const router = express.Router()
const { verifyToken } = require('../middleware/auth')
const { createEntry, getHistory } = require('../controllers/journalController')

router.post('/', verifyToken, createEntry)
router.get('/:patientId', verifyToken, getHistory)

module.exports = router
