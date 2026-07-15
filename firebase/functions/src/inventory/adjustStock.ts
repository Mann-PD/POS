/**
 * adjustStock Cloud Function
 *
 * Callable HTTPS.
 * Only Admin or SuperAdmin can call.
 *
 * RESPONSIBILITIES:
 * - Validate role (Admin/SuperAdmin) and shopId
 * - Adjust product stock by a signed adjustment value
 * - Write inventory_logs entry
 * - Write audit_logs entry
 * - All inside a single Firestore transaction
 *
 * CRITICAL RULES:
 * - Never trust frontend data
 * - Stock cannot become negative
 * - Logs are immutable and append-only
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

import { Product } from '../types';
import { validateAdminOrSuper } from '../utils/roleValidation';
import { validateRequiredString } from '../utils/validation';

const db = admin.firestore();

interface AdjustStockPayload {
  productId: string;
  shopId: string;
  adjustment: number;
  reason: string;
}

export const adjustStock = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;
    const payload = data as AdjustStockPayload;

    try {
      const productId = validateRequiredString(
        payload?.productId,
        'productId'
      );
      const shopId = validateRequiredString(payload?.shopId, 'shopId');
      const reason = validateRequiredString(payload?.reason, 'reason');

      const rawAdjustment = (payload as any)?.adjustment;
      if (
        typeof rawAdjustment !== 'number' ||
        isNaN(rawAdjustment) ||
        rawAdjustment === 0
      ) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'adjustment must be a non-zero number'
        );
      }
      const adjustment: number = rawAdjustment;

      let user: Awaited<ReturnType<typeof validateAdminOrSuper>>;
      try {
        user = await validateAdminOrSuper(userId, shopId);
      } catch (e: any) {
        throw new functions.https.HttpsError(
          'permission-denied',
          e?.message ||
            'Access denied. Only Admin or SuperAdmin can adjust inventory.'
        );
      }

      const result = await db.runTransaction(async (transaction) => {
        const now = admin.firestore.Timestamp.now();

        const productRef = db.collection('products').doc(productId);
        const productSnap = await transaction.get(productRef);

        if (!productSnap.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            'Product not found'
          );
        }

        const product = productSnap.data() as Product;

        if (product.shopId !== shopId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            'Product does not belong to this shop'
          );
        }

        const currentStock =
          (product.stock as unknown as number) ?? 0;
        const newStock = currentStock + adjustment;

        if (newStock < 0) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Stock cannot become negative. Current: ${currentStock}, adjustment: ${adjustment}`
          );
        }

        // 1) Update product stock
        transaction.update(productRef, {
          stock: newStock,
        });

        // 2) Create inventory_logs entry
        const invLogRef = db.collection('inventory_logs').doc();
        transaction.set(invLogRef, {
          logId: invLogRef.id,
          productId,
          shopId,
          change: adjustment,
          reason,
          createdAt: now,
        });

        // 3) Create audit_logs entry
        const auditRef = db.collection('audit_logs').doc();
        transaction.set(auditRef, {
          logId: auditRef.id,
          userId: user.userId,
          role: user.role,
          shopId: user.shopId,
          action: 'INVENTORY_ADJUSTMENT',
          entityType: 'product',
          entityId: productId,
          timestamp: now,
          adjustment,
          previousStock: currentStock,
          newStock,
          reason,
          source: 'adjustStock_callable',
        });

        return {
          success: true,
          productId,
          shopId,
          adjustment,
          previousStock: currentStock,
          newStock,
        };
      });

      return result;
    } catch (err: any) {
      if (err instanceof functions.https.HttpsError) {
        throw err;
      }

      console.error('adjustStock failed:', err);

      throw new functions.https.HttpsError(
        'internal',
        err?.message || 'Failed to adjust stock'
      );
    }
  }
);

