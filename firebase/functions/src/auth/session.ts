/**
 * Session management utilities - concurrent login restriction.
 *
 * Callable: setActiveSession
 * - Records current activeSessionId for a user.
 * - Used by client after successful login.
 *
 * NOTE: Firestore rules do not expose this directly; writes are done via Admin SDK.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateRequiredString } from '../utils/validation';

const db = admin.firestore();

export const setActiveSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const sessionId = validateRequiredString(data?.sessionId, 'sessionId');

  try {
    await db.collection('users').doc(userId).set(
      {
        activeSessionId: sessionId,
        activeSessionUpdatedAt: admin.firestore.Timestamp.now(),
      },
      { merge: true }
    );

    return { success: true, sessionId };
  } catch (error: any) {
    console.error('Error setting active session:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to set active session'
    );
  }
});

