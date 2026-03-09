/**
 * createAdminUser Cloud Function
 * Super Admin only: creates a new Admin user (Firebase Auth + Firestore users doc).
 * Caller remains signed in; no client-side Auth switch.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateRequiredString } from '../utils/validation';
import { Role } from '../types/canonicalEnums';

const db = admin.firestore();
const auth = admin.auth();

// Removed unused interface

export const createAdminUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated'
    );
  }

  const callerId = context.auth.uid;
  const userDoc = await db.collection('users').doc(callerId).get();
  if (!userDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'User not found'
    );
  }

  const caller = userDoc.data() as { role: string; status: string };
  const role = (caller.role || '').replace(/\s+/g, '');
  if (role !== 'SuperAdmin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only Super Admin can create Admin users'
    );
  }

  if (caller.status !== 'Active') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Account is not active'
    );
  }

  const name = validateRequiredString(data?.name, 'name');
  const email = validateRequiredString(data?.email, 'email').trim().toLowerCase();
  const phone = validateRequiredString(data?.phone, 'phone');
  const shopId = validateRequiredString(data?.shopId, 'shopId');
  const password = validateRequiredString(data?.password, 'password');
  if (password.length < 6) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Password must be at least 6 characters'
    );
  }

  const existing = await db.collection('users').where('email', '==', email).get();
  if (!existing.empty) {
    throw new functions.https.HttpsError(
      'already-exists',
      'An account with this email already exists'
    );
  }

  const newUser = await auth.createUser({
    email,
    password,
    displayName: name,
  });

  const userId = newUser.uid;
  const now = admin.firestore.Timestamp.now();
  await db.collection('users').doc(userId).set({
    userId,
    name,
    email,
    phone,
    role: Role.Admin,
    shopId,
    status: 'Active',
    createdAt: now,
  });

  const logId = db.collection('audit_logs').doc().id;
  await db.collection('audit_logs').doc(logId).set({
    logId,
    userId: callerId,
    role: 'SuperAdmin',
    shopId: '',
    action: 'admin_user_created',
    entityType: 'user',
    entityId: userId,
    timestamp: now,
  });

  return { success: true, userId };
});
