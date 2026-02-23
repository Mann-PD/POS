/**
 * Inventory Logs Helper
 * 
 * LOCATION: firebase/functions/src/inventory/inventoryLogs.ts
 * 
 * RESPONSIBILITIES:
 * - Create immutable inventory_logs records
 * - Store productId, shopId, quantity change, reason, timestamp
 * - Ensure logs are append-only
 * - Export reusable helper function
 * 
 * CRITICAL BUSINESS RULES ENFORCED:
 * - Inventory logs are immutable (append-only)
 * - All stock changes must be logged
 * - Logs can only be created via Cloud Functions
 * - Never trust frontend data - all inputs validated
 * 
 * Based on TECHNICAL REQUIREMENTS IN DETAIL.md - Module 8: INVENTORY LOGS
 */

import * as admin from 'firebase-admin';
import { InventoryLog } from '../types';
import { validateRequiredString } from '../utils/validation';

const db = admin.firestore();

/**
 * Creates an immutable inventory log entry
 * 
 * Inventory logs are append-only and cannot be modified or deleted.
 * All stock changes must be logged for audit and tracking purposes.
 * 
 * @param productId - The product ID that had inventory change
 * @param shopId - The shop ID (for data isolation)
 * @param change - The quantity change (positive for addition, negative for deduction)
 * @param reason - Human-readable reason for the inventory change
 * @returns Promise<string> - The created log ID
 * 
 * @throws Error if validation fails
 */
export async function createInventoryLog(
  productId: string,
  shopId: string,
  change: number,
  reason: string
): Promise<string> {
  // Validate all inputs - never trust frontend data
  const validatedProductId = validateRequiredString(productId, 'productId');
  const validatedShopId = validateRequiredString(shopId, 'shopId');
  const validatedReason = validateRequiredString(reason, 'reason');
  
  // Validate change is a number (can be negative for deductions, positive for additions)
  if (typeof change !== 'number' || isNaN(change)) {
    throw new Error('change must be a valid number');
  }

  // Validate change is not zero (no point logging zero changes)
  if (change === 0) {
    throw new Error('change cannot be zero');
  }

  // Generate unique log ID
  const logId = db.collection('inventory_logs').doc().id;
  
  // Get current timestamp
  const timestamp = admin.firestore.Timestamp.now();

  // Create inventory log object
  const inventoryLog: InventoryLog = {
    logId,
    productId: validatedProductId,
    shopId: validatedShopId,
    change, // Can be positive (addition) or negative (deduction)
    reason: validatedReason,
    createdAt: timestamp, // Immutable timestamp
  };

  // Write to Firestore - append-only operation
  // Firestore security rules should prevent updates/deletes
  await db.collection('inventory_logs').doc(logId).set(inventoryLog);

  console.log(`Inventory log created: ${logId} for product ${validatedProductId}, change: ${change}, reason: ${validatedReason}`);

  return logId;
}

/**
 * Creates multiple inventory log entries in batch
 * Useful for order confirmations with multiple products
 * 
 * @param logs - Array of inventory log data
 * @returns Promise<string[]> - Array of created log IDs
 */
export async function createInventoryLogsBatch(
  logs: Array<{
    productId: string;
    shopId: string;
    change: number;
    reason: string;
  }>
): Promise<string[]> {
  if (!Array.isArray(logs) || logs.length === 0) {
    throw new Error('logs must be a non-empty array');
  }

  const batch = db.batch();
  const logIds: string[] = [];
  const timestamp = admin.firestore.Timestamp.now();

  for (const log of logs) {
    // Validate each log entry
    const validatedProductId = validateRequiredString(log.productId, 'productId');
    const validatedShopId = validateRequiredString(log.shopId, 'shopId');
    const validatedReason = validateRequiredString(log.reason, 'reason');

    if (typeof log.change !== 'number' || isNaN(log.change)) {
      throw new Error('change must be a valid number for all log entries');
    }

    if (log.change === 0) {
      throw new Error('change cannot be zero for any log entry');
    }

    const logId = db.collection('inventory_logs').doc().id;
    logIds.push(logId);

    const inventoryLog: InventoryLog = {
      logId,
      productId: validatedProductId,
      shopId: validatedShopId,
      change: log.change,
      reason: validatedReason,
      createdAt: timestamp,
    };

    batch.set(db.collection('inventory_logs').doc(logId), inventoryLog);
  }

  // Commit all logs atomically
  await batch.commit();

  console.log(`Created ${logIds.length} inventory logs in batch`);

  return logIds;
}

/**
 * Gets inventory logs for a specific product
 * Read-only operation for reporting/audit purposes
 * 
 * @param productId - The product ID to get logs for
 * @param shopId - The shop ID (for data isolation)
 * @param limit - Maximum number of logs to return (default: 100)
 * @returns Promise<InventoryLog[]> - Array of inventory logs
 */
export async function getInventoryLogsForProduct(
  productId: string,
  shopId: string,
  limit: number = 100
): Promise<InventoryLog[]> {
  const validatedProductId = validateRequiredString(productId, 'productId');
  const validatedShopId = validateRequiredString(shopId, 'shopId');

  if (typeof limit !== 'number' || limit < 1 || limit > 1000) {
    throw new Error('limit must be a number between 1 and 1000');
  }

  const snapshot = await db.collection('inventory_logs')
    .where('productId', '==', validatedProductId)
    .where('shopId', '==', validatedShopId)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map(doc => doc.data() as InventoryLog);
}

/**
 * Gets inventory logs for a specific shop
 * Read-only operation for reporting/audit purposes
 * 
 * @param shopId - The shop ID
 * @param limit - Maximum number of logs to return (default: 100)
 * @returns Promise<InventoryLog[]> - Array of inventory logs
 */
export async function getInventoryLogsForShop(
  shopId: string,
  limit: number = 100
): Promise<InventoryLog[]> {
  const validatedShopId = validateRequiredString(shopId, 'shopId');

  if (typeof limit !== 'number' || limit < 1 || limit > 1000) {
    throw new Error('limit must be a number between 1 and 1000');
  }

  const snapshot = await db.collection('inventory_logs')
    .where('shopId', '==', validatedShopId)
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map(doc => doc.data() as InventoryLog);
}
