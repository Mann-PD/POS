/**
 * Role and permission validation utilities
 * Enforces strict RBAC from requirements
 */

import * as admin from 'firebase-admin';
import { UserRole, UserStatus, User } from '../types';
import { validateShopId, validateUserId } from './validation';

const db = admin.firestore();

/**
 * Validates user role and shopId access
 * Throws error if validation fails
 */
export async function validateRoleAndShop(
  userId: string,
  shopId: string,
  allowedRoles: UserRole[],
  allowCrossShop: boolean = false
): Promise<User> {
  validateUserId(userId);
  validateShopId(shopId);

  const userDoc = await db.collection('users').doc(userId).get();
  
  if (!userDoc.exists) {
    throw new Error('User not found');
  }

  const user = userDoc.data() as User;

  // Check if user is active (canonical status 'Active')
  if (user.status !== UserStatus.ACTIVE) {
    throw new Error('User account is not active');
  }

  // Check role
  if (!allowedRoles.includes(user.role as UserRole)) {
    throw new Error(`Access denied. Required role: ${allowedRoles.join(', ')}`);
  }

  // Check shopId access (Super Admin can access all shops)
  if (!allowCrossShop && user.role !== UserRole.SUPER_ADMIN) {
    if (user.shopId !== shopId) {
      throw new Error('Access denied. Shop ID mismatch');
    }
  }

  return user;
}

/**
 * Validates that user is Super Admin
 */
export async function validateSuperAdmin(userId: string): Promise<User> {
  return validateRoleAndShop(userId, 'system', [UserRole.SUPER_ADMIN], true);
}

/**
 * Validates that user is Admin or Super Admin
 */
export async function validateAdminOrSuper(
  userId: string,
  shopId: string
): Promise<User> {
  return validateRoleAndShop(userId, shopId, [UserRole.ADMIN, UserRole.SUPER_ADMIN]);
}

/**
 * Validates that user is Employee
 */
export async function validateEmployee(
  userId: string,
  shopId: string
): Promise<User> {
  return validateRoleAndShop(userId, shopId, [UserRole.EMPLOYEE]);
}

/**
 * Validates that user can access shop data
 */
export async function validateShopAccess(
  userId: string,
  shopId: string
): Promise<User> {
  const userDoc = await db.collection('users').doc(userId).get();
  
  if (!userDoc.exists) {
    throw new Error('User not found');
  }

  const user = userDoc.data() as User;

  if (user.status !== UserStatus.ACTIVE) {
    throw new Error('User account is not active');
  }

  // Super Admin can access all shops
  if (user.role === UserRole.SUPER_ADMIN) {
    return user;
  }

  // Others must match shopId
  if (user.shopId !== shopId) {
    throw new Error('Access denied. Shop ID mismatch');
  }

  return user;
}
