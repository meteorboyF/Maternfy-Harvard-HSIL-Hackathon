const express = require('express')
const router = express.Router()
const { verifyFirebaseToken } = require('../middleware/auth')
const { getDietary } = require('../controllers/dietaryController')

// POST /api/dietary — get personalised dietary advice
router.post('/', verifyFirebaseToken, getDietary)

module.exports = router
