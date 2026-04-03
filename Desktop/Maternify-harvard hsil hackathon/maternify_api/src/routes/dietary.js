const express = require('express')
const router = express.Router()
const { verifyToken } = require('../middleware/auth')
const { getDietary } = require('../controllers/dietaryController')

// POST /api/dietary — get personalised dietary advice
router.post('/', verifyToken, getDietary)

module.exports = router
