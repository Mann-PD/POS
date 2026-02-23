/**
 * Inventory log creation utility
 * Creates immutable inventory logs for all stock changes
 */

import * as admin from 'firebase-admin';
import { InventoryLog } from '../types';

const db = admin.firestore();

/**
 * Creates an inventory log entry
 * Inventory logs are immutable and created only via Cloud Functions
 */
export async function createInventoryLog(
  productId: string,
  shopId: string,
  change: number,
  reason: string
): Promise<string> {
  const logId = db.collection('inventory_logs').doc().id;
  const timestamp = admin.firestore.Timestamp.now();

  const inventoryLog: InventoryLog = {
    logId,
    productId,
    shopId,
    change,
    reason,
    createdAt: timestamp,
  };

  await db.collection('inventory_logs').doc(logId).set(inventoryLog);
  
  return logId;
}
