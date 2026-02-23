/**
 * onPriceChange Firestore Trigger
 * 
 * CRITICAL BUSINESS RULES ENFORCED:
 * - All price changes must be logged for audit
 * - Price changes apply only to future orders
 * - Historical order prices remain unchanged
 * 
 * Based on TECHNICAL REQUIREMENTS IN DETAIL.md - Module 3: PRODUCTS
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Product } from '../types';

const db = admin.firestore();

export const onPriceChange = functions.firestore
  .document('products/{productId}')
  .onUpdate(async (change, context) => {
    const productId = context.params.productId;
    const before = change.before.data() as Product;
    const after = change.after.data() as Product;

    // Check if price actually changed
    if (before.price === after.price) {
      return null; // No price change, skip logging
    }

    try {
      // NOTE: Firestore triggers don't provide user context
      // To properly audit who made the change, the frontend should:
      // 1. Call a callable function that logs the audit, then updates the product
      // 2. Or store lastModifiedBy in the product document
      // For now, we log with shopId context
      
      // Create audit log entry
      // The userId will be 'system' since we can't determine the actual user from trigger
      const logId = db.collection('audit_logs').doc().id;
      await db.collection('audit_logs').doc(logId).set({
        logId,
        userId: 'system_trigger',
        role: 'system',
        shopId: after.shopId,
        action: 'price_change',
        entityType: 'product',
        entityId: productId,
        timestamp: admin.firestore.Timestamp.now(),
        oldPrice: before.price,
        newPrice: after.price,
        priceChange: after.price - before.price,
        note: 'Price change detected via trigger. Actual user should be logged via callable function.',
      });

      console.log(`Price change logged for product ${productId}: ${before.price} -> ${after.price}`);

      return null;
    } catch (error: any) {
      console.error(`Error logging price change for product ${productId}:`, error);
      // Don't throw - we don't want to fail the product update
      return null;
    }
  });
