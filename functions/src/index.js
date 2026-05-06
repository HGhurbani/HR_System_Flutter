const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

admin.initializeApp();

const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

exports.processManagedUserCreation = onDocumentCreated(
  'admin_user_creation_requests/{requestId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const requestRef = snapshot.ref;

    await requestRef.update({
      status: 'processing',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      const userRecord = await admin.auth().createUser({
        email: data.email,
        password: data.temporaryPassword,
        displayName: data.fullName,
        disabled: data.isActive === false,
      });

      await db.collection('users').doc(userRecord.uid).set({
        fullName: data.fullName,
        email: data.email,
        phone: emptyToNull(data.phone),
        role: data.role,
        position: emptyToNull(data.position),
        department: emptyToNull(data.department),
        employeeCode: emptyToNull(data.employeeCode),
        hireDate: data.hireDate || null,
        weeklyRestDaysMode: normalizeWeeklyRestDaysMode(data.weeklyRestDaysMode),
        customWeeklyRestDays: sanitizeWeeklyRestDays(data.customWeeklyRestDays),
        languagePreference: 'ar',
        isActive: data.isActive !== false,
        mustChangePassword: data.mustChangePassword !== false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await requestRef.update({
        status: 'completed',
        createdUserId: userRecord.uid,
        errorMessage: null,
        temporaryPassword: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      await requestRef.update({
        status: 'failed',
        errorMessage: error.message || 'Managed user creation failed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  },
);

function emptyToNull(value) {
  if (typeof value !== 'string') return value || null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeWeeklyRestDaysMode(value) {
  return value === 'custom' ? 'custom' : 'company';
}

function sanitizeWeeklyRestDays(value) {
  if (!Array.isArray(value)) return [];
  const days = [...new Set(
    value
      .map((day) => Number(day))
      .filter((day) => Number.isInteger(day) && day >= 1 && day <= 7),
  )].sort((a, b) => a - b);
  return days.length >= 7 ? [] : days;
}
