/**
 * confirmOrder Cloud Function
 *
 * Callable HTTPS. Only role = Employee can call.
 *
 * Accepts full cart + payment data from client.
 * Creates order, order_items, deducts inventory, writes
 * inventory_logs and audit_logs — ALL inside ONE Firestore
 * transaction. Returns orderId to client.
 *
 * Client MUST NOT pre-write any order documents.
 * Ghost orders are impossible because everything is atomic.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  Product,
  Customer,
} from '../types';
import { OrderStatus, PaymentStatus } from '../types/canonicalEnums';
import { validateEmployee } from '../utils/roleValidation';
import { validateRequiredString } from '../utils/validation';

const db = admin.firestore();

interface CartItem {
  productId: string;
  quantityOrWeight: number;
  priceSnapshot: number;
  totalPrice: number;
}

interface ConfirmOrderPayload {
  customerId: string;
  shopId: string;
  paymentMethod: string;
  totalAmount: number;
  items: CartItem[];
}

export const confirmOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const payload = data as ConfirmOrderPayload;

  // Basic top-level validation (no transaction yet)
  const shopId = validateRequiredString(payload?.shopId, 'shopId');
  const customerId = validateRequiredString(payload?.customerId, 'customerId');
  const paymentMethod = validateRequiredString(payload?.paymentMethod, 'paymentMethod');

  if (
    typeof payload?.totalAmount !== 'number' ||
    payload.totalAmount <= 0
  ) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'totalAmount must be a positive number'
    );
  }

  if (!Array.isArray(payload?.items) || payload.items.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'items must be a non-empty array'
    );
  }

  for (const item of payload.items) {
    if (!item.productId || typeof item.productId !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'Each item must have a productId string');
    }
    if (typeof item.quantityOrWeight !== 'number' || item.quantityOrWeight <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Each item quantityOrWeight must be > 0');
    }
    if (typeof item.priceSnapshot !== 'number' || item.priceSnapshot <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Each item priceSnapshot must be > 0');
    }
    if (typeof item.totalPrice !== 'number' || item.totalPrice <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Each item totalPrice must be > 0');
    }
  }

  // Only Employee role may confirm orders; shopId must match
  let user: { userId: string; role: string; shopId: string; name: string; email: string; status: string };
  try {
    user = await validateEmployee(userId, shopId);
  } catch (e: any) {
    throw new functions.https.HttpsError(
      'permission-denied',
      e?.message || 'Access denied. Only Employee role can confirm orders and shopId must match.'
    );
  }

  try {
    const result = await db.runTransaction(async (transaction) => {
      const now = admin.firestore.Timestamp.now();

      // ── 1. Validate customer ───────────────────────────────────────────────
      const customerRef = db.collection('customers').doc(customerId);
      const customerSnap = await transaction.get(customerRef);
      if (!customerSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Customer not found');
      }
      const customer = customerSnap.data() as Customer;
      if (customer.shopId !== shopId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Customer does not belong to this shop'
        );
      }

      // ── 2. Validate all products and compute inventory deductions ──────────
      const PRICE_TOLERANCE = 0.01;

      const inventoryUpdates: Array<{
        productRef: admin.firestore.DocumentReference;
        newStock: number;
        quantity: number;
        productId: string;
      }> = [];

      let calculatedTotalAmount = 0;

      for (const item of payload.items) {
        const productRef = db.collection('products').doc(item.productId);
        const productSnap = await transaction.get(productRef);

        if (!productSnap.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            `Product ${item.productId} not found`
          );
        }

        const product = productSnap.data() as Product;

        if (product.shopId !== shopId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            `Product ${item.productId} does not belong to this shop`
          );
        }

        // Accept both enum value ('active') and Firestore stored value ('Active')
        if (
          (product.status as string) !== 'Active' &&
          (product.status as string) !== 'active'
        ) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Product ${product.name} is not active`
          );
        }

        // ── Price integrity check 1: priceSnapshot must match product.price ──
        if (Math.abs(item.priceSnapshot - product.price) > PRICE_TOLERANCE) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            `Price mismatch for product ${product.name}: ` +
            `client sent ${item.priceSnapshot}, server has ${product.price}`
          );
        }

        const qty = item.quantityOrWeight;

        // ── Price integrity check 2: totalPrice must equal priceSnapshot × qty ──
        const expectedItemTotal = product.price * qty;
        if (Math.abs(item.totalPrice - expectedItemTotal) > PRICE_TOLERANCE) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            `Item total mismatch for product ${product.name}: ` +
            `client sent ${item.totalPrice}, expected ${expectedItemTotal} (${product.price} × ${qty})`
          );
        }

        // Accumulate server-calculated total using authoritative price
        calculatedTotalAmount += expectedItemTotal;

        if (product.stock < qty) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Insufficient stock for product ${product.name}: available ${product.stock}, required ${qty}`
          );
        }

        const newStock = product.stock - qty;
        if (newStock < 0) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Stock cannot become negative for product ${product.name}`
          );
        }

        inventoryUpdates.push({
          productRef,
          newStock,
          quantity: qty,
          productId: item.productId,
        });
      }

      // ── Price integrity check 3: totalAmount must match server recalculation ──
      if (Math.abs(payload.totalAmount - calculatedTotalAmount) > PRICE_TOLERANCE) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Order totalAmount mismatch: client sent ${payload.totalAmount}, ` +
          `server calculated ${calculatedTotalAmount}`
        );
      }

      // ── 3. Create order document ───────────────────────────────────────────
      const orderRef = db.collection('orders').doc();
      const orderId = orderRef.id;

      transaction.set(orderRef, {
        orderId,
        shopId,
        customerId,
        employeeId: userId,
        totalAmount: calculatedTotalAmount,  // server-calculated; never trust client
        paymentMethod,
        paymentStatus: PaymentStatus.Success,   // 'Success'
        orderStatus: OrderStatus.locked,        // 'locked' — immediately locked
        createdAt: now,
      });

      // ── 4. Create order_items documents ───────────────────────────────────
      const orderItemsRef = db.collection('order_items');
      for (const item of payload.items) {
        const itemRef = orderItemsRef.doc();
        transaction.set(itemRef, {
          orderItemId: itemRef.id,
          orderId,
          shopId,
          productId: item.productId,
          quantityOrWeight: item.quantityOrWeight,
          priceSnapshot: item.priceSnapshot,
          totalPrice: item.totalPrice,
        });
      }

      // ── 5. Deduct inventory ────────────────────────────────────────────────
      for (const u of inventoryUpdates) {
        transaction.update(u.productRef, { stock: u.newStock });
      }

      // ── 6. Write inventory_logs ────────────────────────────────────────────
      for (const u of inventoryUpdates) {
        const logRef = db.collection('inventory_logs').doc();
        transaction.set(logRef, {
          logId: logRef.id,
          productId: u.productId,
          shopId,
          change: -u.quantity,
          reason: `Order ${orderId} confirmation — stock deduction`,
          createdAt: now,
        });
      }

      // ── 7. Write audit_log ────────────────────────────────────────────────
      const auditRef = db.collection('audit_logs').doc();
      transaction.set(auditRef, {
        logId: auditRef.id,
        userId: user.userId,
        role: user.role,
        shopId: user.shopId,
        action: 'ORDER_CONFIRMED',
        entityType: 'order',
        entityId: orderId,
        timestamp: now,
        totalAmount: calculatedTotalAmount,  // server-calculated
        paymentMethod,
        itemCount: payload.items.length,
      });

      return {
        success: true,
        orderId,
        orderStatus: OrderStatus.locked,
        totalAmount: calculatedTotalAmount,  // server-calculated
        paymentMethod,
        itemCount: payload.items.length,
      };
    });

    return result;
  } catch (err: any) {
    if (err instanceof functions.https.HttpsError) throw err;
    throw new functions.https.HttpsError(
      'internal',
      err?.message || 'Failed to confirm order'
    );
  }
});
