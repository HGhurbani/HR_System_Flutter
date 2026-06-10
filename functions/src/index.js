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

exports.processManagedUserUpdate = onDocumentCreated(
  'admin_user_update_requests/{requestId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const requestRef = snapshot.ref;
    const targetUserId = data.targetUserId;
    const requestedByAdminId = data.requestedByAdminId;
    const normalizedEmail =
      typeof data.email === 'string' ? data.email.trim().toLowerCase() : '';

    await requestRef.update({
      status: 'processing',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    try {
      if (!targetUserId || !requestedByAdminId || !normalizedEmail) {
        throw new Error('Missing required managed user update fields');
      }

      const adminSnapshot = await db.collection('users')
        .doc(requestedByAdminId)
        .get();
      const adminData = adminSnapshot.data();
      if (!adminSnapshot.exists ||
          adminData.role !== 'admin' ||
          adminData.isActive !== true) {
        throw new Error('Only an active administrator can update users');
      }

      const targetRef = db.collection('users').doc(targetUserId);
      const targetSnapshot = await targetRef.get();
      if (!targetSnapshot.exists) {
        throw new Error('Target user was not found');
      }

      const targetData = targetSnapshot.data();
      const previousEmail = targetData.email || '';
      const emailChanged = previousEmail.toLowerCase() !== normalizedEmail;

      if (emailChanged) {
        await admin.auth().updateUser(targetUserId, { email: normalizedEmail });
      }

      try {
        await targetRef.update({
          fullName: data.fullName,
          email: normalizedEmail,
          phone: emptyToNull(data.phone),
          position: emptyToNull(data.position),
          department: emptyToNull(data.department),
          employeeCode: emptyToNull(data.employeeCode),
          hireDate: data.hireDate || null,
          weeklyRestDaysMode:
            normalizeWeeklyRestDaysMode(data.weeklyRestDaysMode),
          customWeeklyRestDays:
            sanitizeWeeklyRestDays(data.customWeeklyRestDays),
          isActive: data.isActive !== false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        if (emailChanged && previousEmail) {
          try {
            await admin.auth().updateUser(targetUserId, {
              email: previousEmail,
            });
          } catch (rollbackError) {
            console.error('Unable to roll back Auth email', rollbackError);
          }
        }
        throw firestoreError;
      }

      await requestRef.update({
        status: 'completed',
        errorCode: null,
        errorMessage: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      await requestRef.update({
        status: 'failed',
        errorCode: error.code || 'managed-user-update-failed',
        errorMessage: error.message || 'Managed user update failed',
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
