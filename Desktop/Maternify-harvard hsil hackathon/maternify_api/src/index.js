require('dotenv').config()
const express = require('express')
const cors = require('cors')
const helmet = require('helmet')
const morgan = require('morgan')
const rateLimit = require('express-rate-limit')

const triageRouter = require('./routes/triage')
const patientsRouter = require('./routes/patients')
const alertsRouter = require('./routes/alerts')
const vitalsRouter = require('./routes/vitals')
const authRouter = require('./routes/auth')

const app = express()
const PORT = process.env.PORT || 3000

// Security & middleware
app.use(helmet())
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') || '*' }))
app.use(morgan('combined'))
app.use(express.json({ limit: '10mb' }))

// Rate limiting
const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 })
app.use('/api/', limiter)

// Routes
app.use('/api/auth', authRouter)
app.use('/api/triage', triageRouter)
app.use('/api/patients', patientsRouter)
app.use('/api/alerts', alertsRouter)
app.use('/api/vitals', vitalsRouter)

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', service: 'maternify-api' }))

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' })
})

app.listen(PORT, () => console.log(`Maternify API running on port ${PORT}`))

module.exports = app
