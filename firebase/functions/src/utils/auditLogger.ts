/**
 * Audit logging utility
 * Creates immutable audit logs for all critical actions
 */

import * as admin from 'firebase-admin';
import { AuditLog } from '../types';

/** Minimal user shape required by audit logging — only fields actually used. */
interface AuditUser {
  userId: string;
  role: string;
  shopId: string;
}

const db = admin.firestore();

/**
 * Creates an audit log entry
 * Audit logs are append-only and immutable
 */
export async function createAuditLog(
  user: AuditUser,
  action: string,
  entityType: string,
  entityId: string,
  additionalData?: Record<string, any>
): Promise<void> {
  const logId = db.collection('audit_logs').doc().id;
  const timestamp = admin.firestore.Timestamp.now();

  const auditLog: AuditLog = {
    logId,
    userId: user.userId,
    role: user.role,
    shopId: user.shopId,
    action,
    entityType,
    entityId,
    timestamp,
  };

  // Add additional data if provided
  const logData: any = { ...auditLog };
  if (additionalData) {
    Object.assign(logData, additionalData);
  }

  await db.collection('audit_logs').doc(logId).set(logData);
}

/**
 * Logs authentication events
 */
export async function logAuthEvent(
  userId: string,
  action: string,
  success: boolean,
  errorMessage?: string
): Promise<void> {
  const userDoc = await db.collection('users').doc(userId).get();
  
  if (!userDoc.exists) {
    // Log failed login attempt with unknown user
    const logId = db.collection('audit_logs').doc().id;
    await db.collection('audit_logs').doc(logId).set({
      logId,
      userId: userId || 'unknown',
      role: 'unknown',
      shopId: 'unknown',
      action,
      entityType: 'authentication',
      entityId: userId || 'unknown',
      timestamp: admin.firestore.Timestamp.now(),
      success,
      errorMessage: errorMessage || null,
    });
    return;
  }

  const user = userDoc.data() as AuditUser;
  await createAuditLog(
    user,
    action,
    'authentication',
    userId,
    {
      success,
      errorMessage: errorMessage || null,
    }
  );
}

/**
 * Logs price change events
 */
export async function logPriceChange(
  user: AuditUser,
  productId: string,
  oldPrice: number,
  newPrice: number
): Promise<void> {
  await createAuditLog(
    user,
    'price_change',
    'product',
    productId,
    {
      oldPrice,
      newPrice,
      priceChange: newPrice - oldPrice,
    }
  );
}

/**
 * Logs expense changes
 */
export async function logExpenseChange(
  user: AuditUser,
  expenseId: string,
  action: 'create' | 'update' | 'delete',
  amount?: number,
  description?: string
): Promise<void> {
  await createAuditLog(
    user,
    `expense_${action}`,
    'expense',
    expenseId,
    {
      amount: amount || null,
      description: description || null,
    }
  );
}

/**
 * Logs user status changes
 */
export async function logUserStatusChange(
  actor: AuditUser,
  targetUserId: string,
  oldStatus: string,
  newStatus: string
): Promise<void> {
  await createAuditLog(
    actor,
    'user_status_change',
    'user',
    targetUserId,
    {
      oldStatus,
      newStatus,
    }
  );
}

/**
 * Logs order cancellation
 */
export async function logOrderCancellation(
  user: AuditUser,
  orderId: string,
  reason?: string
): Promise<void> {
  await createAuditLog(
    user,
    'order_cancelled',
    'order',
    orderId,
    {
      reason: reason || null,
    }
  );
}

/**
 * Logs inventory changes
 */
export async function logInventoryChange(
  user: AuditUser,
  productId: string,
  change: number,
  reason: string
): Promise<void> {
  await createAuditLog(
    user,
    'inventory_change',
    'product',
    productId,
    {
      change,
      reason,
    }
  );
}
