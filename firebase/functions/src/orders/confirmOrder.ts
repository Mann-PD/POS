/**
 * confirmOrder Cloud Function
 * 
 * TRIGGER TYPE: Callable HTTPS function
 * 
 * CRITICAL BUSINESS RULES ENFORCED:
 * - Validate authenticated user
 * - Validate user role == Employee
 * - Validate shopId match
 * - Validate order exists and is not confirmed/locked
 * - Validate paymentStatus == "Success"
 * - Deduct inventory atomically
 * - Prevent negative stock
 * - Lock order (orderStatus = "Locked")
 * - Write inventory_logs entries
 * - Write audit_logs entry
 * - Use Firestore transaction
 * - Reject duplicate confirmations
 * 
 * FORBIDDEN:
 * - Partial updates
 * - Frontend-trusted values
 * - Direct client inventory updates
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Order, OrderItem, Product, Customer, PaymentStatus, OrderStatus } from '../types';
import { validateEmployee } from '../utils/roleValidation';
import { validateRequiredString } from '../utils/validation';
import { createInventoryLog } from '../utils/inventoryLogs';
import { createAuditLog } from '../utils/auditLogger';

const db = admin.firestore();

interface ConfirmOrderRequest {
  orderId: string;
  shopId: string;
}

export const confirmOrder = functions.https.onCall(async (data, context) => {
  // Validate authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const request = data as ConfirmOrderRequest;

  try {
    // Validate request data - never trust frontend
    const orderId = validateRequiredString(request.orderId, 'orderId');
    const shopId = validateRequiredString(request.shopId, 'shopId');

    // Validate employee role and shop access
    const employee = await validateEmployee(userId, shopId);

    // Use Firestore transaction for atomic operations
    return await db.runTransaction(async (transaction) => {
      // Get order - must exist
      const orderRef = db.collection('orders').doc(orderId);
      const orderDoc = await transaction.get(orderRef);

      if (!orderDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Order not found'
        );
      }

      const order = orderDoc.data() as Order;

      // Validate shopId match
      if (order.shopId !== shopId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Order does not belong to this shop'
        );
      }

      // Validate employeeId match - only the assigned employee can confirm
      if (order.employeeId !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only the assigned employee can confirm this order'
        );
      }

      // Validate order is not already confirmed/locked - reject duplicate confirmations
      if (order.orderStatus === OrderStatus.LOCKED || order.orderStatus === OrderStatus.CONFIRMED) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Order is already confirmed/locked'
        );
      }

      // Validate order is not cancelled
      if (order.orderStatus === OrderStatus.CANCELLED) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Cannot confirm a cancelled order'
        );
      }

      // Validate paymentStatus == "Success" - critical business rule
      if (order.paymentStatus !== PaymentStatus.SUCCESS) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          `Order payment must be successful. Current status: ${order.paymentStatus}`
        );
      }

      // Get customer to validate it exists
      const customerDoc = await transaction.get(
        db.collection('customers').doc(order.customerId)
      );

      if (!customerDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Customer not found'
        );
      }

      const customer = customerDoc.data() as Customer;

      // Validate customer shopId matches
      if (customer.shopId !== shopId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Customer does not belong to this shop'
        );
      }

      // Get all order items
      const orderItemsSnapshot = await transaction.get(
        db.collection('order_items')
          .where('orderId', '==', orderId)
      );

      if (orderItemsSnapshot.empty) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Order has no items'
        );
      }

      const orderItems: OrderItem[] = [];
      const inventoryUpdates: Array<{ productRef: admin.firestore.DocumentReference; newStock: number; quantity: number }> = [];

      // Process each order item and validate stock
      for (const itemDoc of orderItemsSnapshot.docs) {
        const orderItem = itemDoc.data() as OrderItem;
        orderItems.push(orderItem);

        const productId = orderItem.productId;
        const quantityOrWeight = orderItem.quantityOrWeight;

        // Get product
        const productRef = db.collection('products').doc(productId);
        const productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw new functions.https.HttpsError(
            'not-found',
            `Product ${productId} not found`
          );
        }

        const product = productDoc.data() as Product;

        // Validate product shopId
        if (product.shopId !== shopId) {
          throw new functions.https.HttpsError(
            'permission-denied',
            `Product ${productId} does not belong to this shop`
          );
        }

        // Validate product is active
        if (product.status !== 'active') {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Product ${product.name} is not active`
          );
        }

        // Validate stock availability and prevent negative stock
        if (product.stock < quantityOrWeight) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Insufficient stock for ${product.name}. Available: ${product.stock}, Required: ${quantityOrWeight}`
          );
        }

        // Calculate new stock - prevent negative
        const newStock = product.stock - quantityOrWeight;
        if (newStock < 0) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            `Stock cannot go below zero for ${product.name}`
          );
        }

        // Store inventory update for atomic execution
        inventoryUpdates.push({
          productRef,
          newStock,
          quantity: quantityOrWeight,
        });
      }

      // Apply all inventory updates atomically
      for (const update of inventoryUpdates) {
        transaction.update(update.productRef, {
          stock: update.newStock,
        });
      }

      // Lock order - set orderStatus = "Locked"
      transaction.update(orderRef, {
        orderStatus: OrderStatus.LOCKED,
      });

      // Return success data
      return {
        success: true,
        orderId,
        orderStatus: OrderStatus.LOCKED,
        totalAmount: order.totalAmount,
        paymentMethod: order.paymentMethod,
        itemCount: orderItems.length,
      };
    }).then(async (result) => {
      // After transaction succeeds, create inventory logs and audit log
      // These are created outside the transaction to avoid transaction size limits
      try {
        // Get order items again for logging
        const orderItemsSnapshot = await db.collection('order_items')
          .where('orderId', '==', orderId)
          .get();

        // Create inventory logs for each product
        for (const itemDoc of orderItemsSnapshot.docs) {
          const orderItem = itemDoc.data() as OrderItem;
          
          await createInventoryLog(
            orderItem.productId,
            shopId,
            -orderItem.quantityOrWeight, // Negative for deduction
            `Order ${orderId} confirmation - Stock deduction`
          );
        }

        // Create audit log entry
        await createAuditLog(
          employee,
          'order_confirmed',
          'order',
          orderId,
          {
            totalAmount: result.totalAmount,
            paymentMethod: result.paymentMethod,
            itemCount: result.itemCount,
            previousStatus: OrderStatus.PENDING,
            newStatus: OrderStatus.LOCKED,
          }
        );

        console.log(`Order ${orderId} confirmed and locked successfully`);
      } catch (logError) {
        // Log error but don't fail the function
        // The order is already locked, so we log the error for investigation
        console.error('Failed to create audit/inventory logs after order confirmation:', logError);
      }

      return result;
    });

  } catch (error: any) {
    console.error('Error confirming order:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to confirm order: ${error.message}`
    );
  }
});
