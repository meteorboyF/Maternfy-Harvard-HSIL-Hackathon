const express = require('express')
const router = express.Router()
const Joi = require('joi')
const { verifyFirebaseToken } = require('../middleware/auth')
const { registerProvider, registerPatient, setUserRole } = require('../services/authService')

const patientSchema = Joi.object({
  name: Joi.string().min(2).max(100).required(),
  age: Joi.number().integer().min(10).max(60).required(),
  phone: Joi.string().pattern(/^01[3-9]\d{8}$/).required(),
  gravida: Joi.number().integer().min(1).required(),
  parity: Joi.number().integer().min(0).required(),
  weeks_gestation: Joi.number().integer().min(0).max(42).required(),
  blood_type: Joi.string().valid('A+','A-','B+','B-','AB+','AB-','O+','O-').required(),
  provider_id: Joi.string().required(),
})

// POST /api/auth/register-provider
router.post('/register-provider', verifyFirebaseToken, async (req, res, next) => {
  try {
    const { uid, name, email } = req.user
    await registerProvider(uid, name, email)
    res.json({ message: 'Provider registered', uid })
  } catch (err) {
    next(err)
  }
})

// POST /api/auth/register-patient
router.post('/register-patient', verifyFirebaseToken, async (req, res, next) => {
  try {
    const { error, value } = patientSchema.validate(req.body)
    if (error) return res.status(400).json({ error: error.details[0].message })

    const patient = await registerPatient(req.user.uid, value)
    res.status(201).json(patient)
  } catch (err) {
    next(err)
  }
})

module.exports = router
