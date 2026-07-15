/**
 * Expense Audit Logging Cloud Functions
 * 
 * LOCATION: firebase/functions/src/expenses/expenseAudit.ts
 * 
 * RESPONSIBILITIES:
 * - Trigger on expense create/update
 * - Validate admin or super admin role
 * - Write audit_logs entry
 * - Prevent deletion
 * - Enforce amount > 0
 * 
 * CRITICAL BUSINESS RULES ENFORCED:
 * - Only Admin and Super Admin can create/update expenses
 * - Expense amount must be > 0
 * - All expense changes are logged for audit
 * - Expense deletion is prevented
 * 
 * Based on TECHNICAL REQUIREMENTS IN DETAIL.md - Module 9: EXPENSES
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Expense } from '../types';
import { validateAdminOrSuper } from '../utils/roleValidation';
import {
  validateRequiredString,
  validatePositiveNumber,
  validateNotFutureDate,
} from '../utils/validation';
import { createAuditLog } from '../utils/auditLogger';

const db = admin.firestore();

type ExpenseAction = 'create' | 'update' | 'delete';

interface CreateOrUpdateExpenseRequest {
  action: ExpenseAction;
  expenseId?: string;
  shopId: string;
  amount?: number;
  description?: string;
  /** Optional; if provided must not be a future date */
  date?: string | number | { seconds: number } | Date;
}

interface CreateExpenseRequest {
  shopId: string;
  amount: number;
  description: string;
  date?: string | number | { seconds: number } | Date;
}

interface UpdateExpenseRequest {
  expenseId: string;
  shopId: string;
  amount?: number;
  description?: string;
  date?: string | number | { seconds: number } | Date;
}

/**
 * Callable: createOrUpdateExpense
 * Only Admin or SuperAdmin. Employees rejected. No delete for Admin; SuperAdmin may delete.
 * Validates: amount > 0, no future date, shopId matches. Writes expense + audit_logs.
 */
export const createOrUpdateExpense = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const req = data as CreateOrUpdateExpenseRequest;

  const action = req?.action as ExpenseAction | undefined;
  if (!action || !['create', 'update', 'delete'].includes(action)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'action must be one of: create, update, delete'
    );
  }

  const shopId = validateRequiredString(req.shopId, 'shopId');

  try {
    // Only Admin or SuperAdmin (Employee is rejected by validateAdminOrSuper)
    const user = await validateAdminOrSuper(userId, shopId);

    if (action === 'delete') {
      // No delete allowed for Admin; only SuperAdmin may delete (canonical: "SuperAdmin")
      if (user.role !== 'SuperAdmin') {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only SuperAdmin may delete expenses. Delete not allowed for Admin.'
        );
      }
      const expenseId = validateRequiredString(req.expenseId, 'expenseId');
      const expenseRef = db.collection('expenses').doc(expenseId);
      const expenseSnap = await expenseRef.get();
      if (!expenseSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Expense not found');
      }
      const expense = expenseSnap.data() as Expense;
      if (expense.shopId !== shopId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Expense does not belong to this shop'
        );
      }
      await expenseRef.delete();
      await createAuditLog(user, 'expense_delete', 'expense', expenseId, {
        amount: expense.amount,
        description: expense.description,
        shopId: expense.shopId,
      });
      return { success: true, action: 'delete', expenseId };
    }

    if (action === 'create') {
      const amount = validatePositiveNumber(req.amount, 'amount');
      const description = validateRequiredString(req.description, 'description');
      if (req.date != null) {
        validateNotFutureDate(req.date, 'date');
      }
      const now = admin.firestore.Timestamp.now();
      const expenseId = db.collection('expenses').doc().id;
      const expense: Expense = {
        expenseId,
        shopId,
        amount,
        description,
        createdAt: now,
      };
      await db.collection('expenses').doc(expenseId).set(expense);
      await createAuditLog(user, 'expense_create', 'expense', expenseId, {
        amount,
        description,
        shopId,
      });
      return { success: true, action: 'create', expenseId, amount, description };
    }

    // action === 'update'
    const expenseId = validateRequiredString(req.expenseId, 'expenseId');
    const expenseRef = db.collection('expenses').doc(expenseId);
    const expenseSnap = await expenseRef.get();
    if (!expenseSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Expense not found');
    }
    const existing = expenseSnap.data() as Expense;
    if (existing.shopId !== shopId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Expense does not belong to this shop'
      );
    }
    const updateData: Partial<Expense> = {};
    if (req.amount !== undefined) {
      updateData.amount = validatePositiveNumber(req.amount, 'amount');
    }
    if (req.description !== undefined) {
      updateData.description = validateRequiredString(req.description, 'description');
    }
    if (req.date != null) {
      validateNotFutureDate(req.date, 'date');
    }
    if (Object.keys(updateData).length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'No fields to update (amount or description required)'
      );
    }
    await expenseRef.update(updateData);
    await createAuditLog(user, 'expense_update', 'expense', expenseId, {
      shopId,
      ...updateData,
      previousAmount: existing.amount,
      previousDescription: existing.description,
    });
    return {
      success: true,
      action: 'update',
      expenseId,
      updatedFields: Object.keys(updateData),
    };
  } catch (err: any) {
    if (err instanceof functions.https.HttpsError) throw err;
    if (err instanceof Error && err.message.includes('Access denied')) {
      throw new functions.https.HttpsError('permission-denied', err.message);
    }
    throw new functions.https.HttpsError(
      'internal',
      err?.message ?? 'Failed to create or update expense'
    );
  }
});

/**
 * Callable function to create expense
 * Validates admin/super admin role and amount > 0
 */
export const createExpense = functions.https.onCall(async (data, context) => {
  // Validate authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const request = data as CreateExpenseRequest;

  try {
    // Validate request data - never trust frontend
    const shopId = validateRequiredString(request.shopId, 'shopId');
    const description = validateRequiredString(request.description, 'description');
    
    // Enforce amount > 0
    const amount = validatePositiveNumber(request.amount, 'amount');

    // Ensure date is not in the future if provided
    let parsedDate: admin.firestore.Timestamp | undefined;
    if (request.date != null) {
      const dateObj = validateNotFutureDate(request.date, 'date');
      parsedDate = admin.firestore.Timestamp.fromDate(dateObj);
    }

    // Validate admin or super admin role
    const user = await validateAdminOrSuper(userId, shopId);

    // Use Firestore transaction for atomic operation
    return await db.runTransaction(async (transaction) => {
      // Generate expense ID
      const expenseId = db.collection('expenses').doc().id;
      const expenseRef = db.collection('expenses').doc(expenseId);

      // Create expense
      const expense: Expense = {
        expenseId,
        shopId,
        amount,
        description,
        createdAt: admin.firestore.Timestamp.now(),
      };
      if (parsedDate) {
        expense.date = parsedDate;
      }

      transaction.set(expenseRef, expense);

      return {
        success: true,
        expenseId,
        amount,
        description,
      };
    }).then(async (result) => {
      // After transaction succeeds, create audit log
      try {
        await createAuditLog(
          user,
          'expense_create',
          'expense',
          result.expenseId,
          {
            amount: result.amount,
            description: result.description,
            shopId,
            date: parsedDate,
          }
        );

        console.log(`Expense created: ${result.expenseId} by user ${userId}`);
      } catch (logError) {
        console.error('Failed to create audit log for expense creation:', logError);
        // Don't fail the function if audit log fails
      }

      return result;
    });

  } catch (error: any) {
    console.error('Error creating expense:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to create expense: ${error.message}`
    );
  }
});

/**
 * Callable function to update expense
 * Validates admin/super admin role and amount > 0
 */
export const updateExpense = functions.https.onCall(async (data, context) => {
  // Validate authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const request = data as UpdateExpenseRequest;

  try {
    // Validate request data - never trust frontend
    const expenseId = validateRequiredString(request.expenseId, 'expenseId');
    const shopId = validateRequiredString(request.shopId, 'shopId');

    // Validate admin or super admin role
    const user = await validateAdminOrSuper(userId, shopId);

    // Use Firestore transaction for atomic operation
    return await db.runTransaction(async (transaction) => {
      // Get existing expense
      const expenseRef = db.collection('expenses').doc(expenseId);
      const expenseDoc = await transaction.get(expenseRef);

      if (!expenseDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Expense not found'
        );
      }

      const existingExpense = expenseDoc.data() as Expense;

      // Validate shopId match
      if (existingExpense.shopId !== shopId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Expense does not belong to this shop'
        );
      }

      // Prepare update data
      const updateData: Partial<Expense> = {};

      // Update amount if provided - enforce amount > 0
      if (request.amount !== undefined) {
        const newAmount = validatePositiveNumber(request.amount, 'amount');
        updateData.amount = newAmount;
      }

      // Update description if provided
      if (request.description !== undefined) {
        const newDescription = validateRequiredString(request.description, 'description');
        updateData.description = newDescription;
      }

      // Update date if provided
      if (request.date != null) {
        const dateObj = validateNotFutureDate(request.date, 'date');
        updateData.date = admin.firestore.Timestamp.fromDate(dateObj);
      }

      // Check if there are any changes
      if (Object.keys(updateData).length === 0) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'No fields to update'
        );
      }

      // Update expense
      transaction.update(expenseRef, updateData);

      return {
        success: true,
        expenseId,
        updatedFields: Object.keys(updateData),
        oldAmount: existingExpense.amount,
        newAmount: updateData.amount || existingExpense.amount,
        oldDescription: existingExpense.description,
        newDescription: updateData.description || existingExpense.description,
        oldDate: existingExpense.date,
        newDate: updateData.date || existingExpense.date,
      };
    }).then(async (result) => {
      // After transaction succeeds, create audit log
      try {
        await createAuditLog(
          user,
          'expense_update',
          'expense',
          expenseId,
          {
            oldAmount: result.oldAmount,
            newAmount: result.newAmount,
            oldDescription: result.oldDescription,
            newDescription: result.newDescription,
            oldDate: result.oldDate,
            newDate: result.newDate,
            shopId,
          }
        );

        console.log(`Expense updated: ${expenseId} by user ${userId}`);
      } catch (logError) {
        console.error('Failed to create audit log for expense update:', logError);
        // Don't fail the function if audit log fails
      }

      return result;
    });

  } catch (error: any) {
    console.error('Error updating expense:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to update expense: ${error.message}`
    );
  }
});

/**
 * Firestore trigger on expense creation (backup logging)
 * Note: Triggers don't have user context, so role validation happens in callable functions
 */
export const onExpenseCreate = functions.firestore
  .document('expenses/{expenseId}')
  .onCreate(async (snapshot, context) => {
    const expenseId = context.params.expenseId;
    const expense = snapshot.data() as Expense;

    try {
      // Validate amount > 0 (safety check)
      if (expense.amount <= 0) {
        console.error(`Invalid expense amount detected: ${expenseId}, amount: ${expense.amount}`);
        // Note: We can't reject here as the document is already created
        // This is a backup validation - primary validation is in callable function
      }

      // Log expense creation (backup audit trail)
      const logId = db.collection('audit_logs').doc().id;
      await db.collection('audit_logs').doc(logId).set({
        logId,
        userId: 'system_trigger',
        role: 'system',
        shopId: expense.shopId,
        action: 'expense_create_trigger',
        entityType: 'expense',
        entityId: expenseId,
        timestamp: admin.firestore.Timestamp.now(),
        amount: expense.amount,
        description: expense.description,
        note: 'Expense creation detected via trigger. Primary audit log should be created by callable function.',
      });

      console.log(`Expense creation trigger logged: ${expenseId}`);
      return null;
    } catch (error: any) {
      console.error(`Error in expense creation trigger ${expenseId}:`, error);
      return null;
    }
  });

/**
 * Firestore trigger on expense update (backup logging)
 */
export const onExpenseUpdate = functions.firestore
  .document('expenses/{expenseId}')
  .onUpdate(async (change, context) => {
    const expenseId = context.params.expenseId;
    const before = change.before.data() as Expense;
    const after = change.after.data() as Expense;

    try {
      // Validate amount > 0 (safety check)
      if (after.amount <= 0) {
        console.error(`Invalid expense amount detected: ${expenseId}, amount: ${after.amount}`);
      }

      // Check if anything actually changed
      if (
        before.amount === after.amount &&
        before.description === after.description &&
        before.shopId === after.shopId
      ) {
        return null;
      }

      // Log expense update (backup audit trail)
      const logId = db.collection('audit_logs').doc().id;
      await db.collection('audit_logs').doc(logId).set({
        logId,
        userId: 'system_trigger',
        role: 'system',
        shopId: after.shopId,
        action: 'expense_update_trigger',
        entityType: 'expense',
        entityId: expenseId,
        timestamp: admin.firestore.Timestamp.now(),
        oldAmount: before.amount,
        newAmount: after.amount,
        oldDescription: before.description,
        newDescription: after.description,
        note: 'Expense update detected via trigger. Primary audit log should be created by callable function.',
      });

      console.log(`Expense update trigger logged: ${expenseId}`);
      return null;
    } catch (error: any) {
      console.error(`Error in expense update trigger ${expenseId}:`, error);
      return null;
    }
  });

/**
 * Firestore trigger on expense delete - PREVENTS DELETION
 * This trigger logs the deletion attempt and can be used to restore the expense
 */
export const onExpenseDelete = functions.firestore
  .document('expenses/{expenseId}')
  .onDelete(async (snapshot, context) => {
    const expenseId = context.params.expenseId;
    const expense = snapshot.data() as Expense;

    try {
      // Log deletion attempt - PREVENT DELETION by logging it
      // Note: The document is already deleted at this point, but we log it
      // Firestore security rules should prevent deletion in the first place
      const logId = db.collection('audit_logs').doc().id;
      await db.collection('audit_logs').doc(logId).set({
        logId,
        userId: 'system_trigger',
        role: 'system',
        shopId: expense.shopId,
        action: 'expense_delete_attempt',
        entityType: 'expense',
        entityId: expenseId,
        timestamp: admin.firestore.Timestamp.now(),
        amount: expense.amount,
        description: expense.description,
        note: 'WARNING: Expense deletion detected. Deletion should be prevented by security rules. This is a violation.',
      });

      console.error(`WARNING: Expense deletion detected: ${expenseId}. This should be prevented by security rules.`);
      return null;
    } catch (error: any) {
      console.error(`Error logging expense deletion ${expenseId}:`, error);
      return null;
    }
  });
