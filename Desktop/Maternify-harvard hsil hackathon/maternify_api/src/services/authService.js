/**
 * Firebase Auth custom claims service — F3
 * Sets patient/provider role on the Firebase user token.
 * Called at registration or when a provider manually assigns a patient.
 */

const { auth } = require('../config/firebase')
const supabase = require('../config/supabase')

/**
 * Assign a role claim to a Firebase user.
 * @param {string} uid  - Firebase UID
 * @param {'patient'|'provider'} role
 * @param {string} [providerId] - if role=patient, link to their provider
 */
async function setUserRole(uid, role, providerId = null) {
  const claims = { role }
  if (role === 'patient' && providerId) {
    claims.provider_id = providerId
  }
  await auth.setCustomUserClaims(uid, claims)
}

/**
 * Verify a Firebase ID token and return decoded claims.
 * Used by middleware — exported here for reuse in tests.
 */
async function verifyToken(idToken) {
  return auth.verifyIdToken(idToken)
}

/**
 * Register a new provider: set Firebase custom claim + no Supabase row needed
 * (providers are identified purely by Firebase UID in the patients.provider_id column)
 */
async function registerProvider(uid, displayName, email) {
  await setUserRole(uid, 'provider')
  console.log(`Provider registered: ${displayName} (${email}) — uid: ${uid}`)
}

/**
 * Register a new patient:
 * 1. Set Firebase custom claim role=patient
 * 2. Create patients row in Supabase
 */
async function registerPatient(uid, patientData) {
  await setUserRole(uid, 'patient', patientData.provider_id)

  const { data, error } = await supabase
    .from('patients')
    .insert({ ...patientData, id: uid })  // use Firebase UID as patient id
    .select()
    .single()

  if (error) throw error
  return data
}

module.exports = { setUserRole, verifyToken, registerProvider, registerPatient }
