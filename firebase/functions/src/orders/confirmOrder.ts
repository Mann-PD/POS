/**
 * confirmOrder Cloud Function
 *
 * Callable HTTPS. Only role = Employee can call.
 *
 * Validates: authenticated, role == Employee, shopId match,
 * orderStatus == pending, paymentStatus == Success.
 *
 * Transaction: lock order (orderStatus = locked), deduct inventory
 * (stock never negative), create inventory_logs, create audit_logs.
 * Orders are immutable after locking.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  Order,
  OrderItem,
  Product,
  Customer,
  User,
} from '../types';
import { OrderStatus, PaymentStatus } from '../types/canonicalEnums';
import { validateEmployee } from '../utils/roleValidation';
import { validateRequiredString } from '../utils/validation';

const db = admin.firestore();

interface ConfirmOrderRequest {
  orderId: string;
  shopId: string;
}

export const confirmOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const request = data as ConfirmOrderRequest;

  const orderId = validateRequiredString(request?.orderId, 'orderId');
  const shopId = validateRequiredString(request?.shopId, 'shopId');

  // Only role = Employee can call; shopId must match user's shop
  let user: User;
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
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await transaction.get(orderRef);

      if (!orderSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Order not found');
      }

      const order = orderSnap.data() as Order;

      if (order.shopId !== shopId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Order does not belong to this shop'
        );
      }

      if (order.employeeId !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only the assigned employee can confirm this order'
        );
      }

      if (order.orderStatus !== OrderStatus.pending) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          order.orderStatus === OrderStatus.locked
            ? 'Order is already locked; direct edits to locked orders are rejected.'
            : order.orderStatus === OrderStatus.cancelled
              ? 'Cannot confirm a cancelled order.'
              : `Order must be pending. Current orderStatus: ${order.orderStatus}`
        );
      }

      if (order.paymentStatus !== PaymentStatus.Success) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Order payment must be Success. Current paymentStatus: ${order.paymentStatus}`
        );
      }

      const customerSnap = await transaction.get(
        db.collection('customers').doc(order.customerId)
      );
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

      const orderItemsSnap = await transaction.get(
        db.collection('order_items').where('orderId', '==', orderId)
      );
      if (orderItemsSnap.empty) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Order has no items'
        );
      }

      const now = admin.firestore.Timestamp.now();
      const inventoryUpdates: Array<{
        productRef: admin.firestore.DocumentReference;
        newStock: number;
        quantity: number;
        orderItem: OrderItem;
      }> = [];

      for (const itemDoc of orderItemsSnap.docs) {
        const orderItem = itemDoc.data() as OrderItem;
        const productRef = db.collection('products').doc(orderItem.productId);
        const productSnap = await transaction.get(productRef);

        if (!productSnap.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            `Product ${orderItem.productId} not found`
          );
        }

        const product = productSnap.data() as Product;
        if (product.shopId !== shopId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            `Product ${orderItem.productId} does not belong to this shop`
          );
        }
        if (product.status !== 'Active') {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Product ${product.name} is not active`
          );
        }

        const qty = orderItem.quantityOrWeight;
        if (product.stock < qty) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Insufficient stock. Product ${product.productId}: available ${product.stock}, required ${qty}. Stock cannot become negative.`
          );
        }

        const newStock = product.stock - qty;
        if (newStock < 0) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Stock cannot become negative'
          );
        }

        inventoryUpdates.push({
          productRef,
          newStock,
          quantity: qty,
          orderItem,
        });
      }

      // Apply inventory deductions
      for (const u of inventoryUpdates) {
        transaction.update(u.productRef, { stock: u.newStock });
      }

      // Lock order (immutable after this)
      transaction.update(orderRef, {
        orderStatus: OrderStatus.locked,
      });

      // Create inventory_logs entries inside transaction
      for (const u of inventoryUpdates) {
        const logRef = db.collection('inventory_logs').doc();
        transaction.set(logRef, {
          logId: logRef.id,
          productId: u.orderItem.productId,
          shopId,
          change: -u.quantity,
          reason: `Order ${orderId} confirmation - stock deduction`,
          createdAt: now,
        });
      }

      // Create audit_logs entry: userId, role, shopId, action = ORDER_CONFIRMED
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
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod,
        itemCount: orderItemsSnap.size,
      });

      return {
        success: true,
        orderId,
        orderStatus: OrderStatus.locked,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod,
        itemCount: orderItemsSnap.size,
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
