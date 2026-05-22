import * as admin from 'firebase-admin';
import { Role, AccountStatus } from '../types/canonicalEnums';
import { validateShopId, validateUserId } from './validation';
 
// Minimal User shape — matches Firestore document structure
interface User {
  userId: string;
  name: string;
  email: string;
  role: string;
  shopId: string;
  status: string;
}
 
const db = admin.firestore();
 
/**
 * Validates user role and shopId access.
 * Throws error if validation fails.
 */
export async function validateRoleAndShop(
  userId: string,
  shopId: string,
  allowedRoles: Role[],
  allowCrossShop: boolean = false
): Promise<User> {
  validateUserId(userId);
  validateShopId(shopId);
 
  const userDoc = await db.collection('users').doc(userId).get();
 
  if (!userDoc.exists) {
    throw new Error('User not found');
  }
 
  const user = userDoc.data() as User;
 
  // PHASE 2 FIX: Was UserStatus.ACTIVE (did not exist). Now uses AccountStatus.Active = 'Active',
  // which matches Firestore rules: status == 'Active'
  if (user.status !== AccountStatus.Active) {
    throw new Error('User account is not active');
  }
 
  // PHASE 2 FIX: Was UserRole.X (SCREAMING_SNAKE_CASE). Now uses Role.X (PascalCase),
  // matching canonicalEnums.ts and Firestore rules.
  if (!allowedRoles.includes(user.role as Role)) {
    throw new Error(`Access denied. Required role: ${allowedRoles.join(', ')}`);
  }
 
  // Super Admin cross-shop access
  // PHASE 2 FIX: Was UserRole.SUPER_ADMIN. Now Role.SuperAdmin.
  if (!allowCrossShop && user.role !== Role.SuperAdmin) {
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
  return validateRoleAndShop(userId, 'system', [Role.SuperAdmin], true);
}
 
/**
 * Validates that user is Admin or Super Admin
 */
export async function validateAdminOrSuper(
  userId: string,
  shopId: string
): Promise<User> {
  // PHASE 2 FIX: Was [UserRole.ADMIN, UserRole.SUPER_ADMIN]
  return validateRoleAndShop(userId, shopId, [Role.Admin, Role.SuperAdmin]);
}
 
/**
 * Validates that user is Employee
 */
export async function validateEmployee(
  userId: string,
  shopId: string
): Promise<User> {
  // PHASE 2 FIX: Was [UserRole.EMPLOYEE]
  return validateRoleAndShop(userId, shopId, [Role.Employee]);
}
 
/**
 * Validates that user can access shop data (any active, same-shop role)
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
 
  // PHASE 2 FIX: Was UserStatus.ACTIVE. Now AccountStatus.Active.
  if (user.status !== AccountStatus.Active) {
    throw new Error('User account is not active');
  }
 
  // PHASE 2 FIX: Was UserRole.SUPER_ADMIN. Now Role.SuperAdmin.
  if (user.role === Role.SuperAdmin) {
    return user;
  }
 
  if (user.shopId !== shopId) {
    throw new Error('Access denied. Shop ID mismatch');
  }
 
  return user;
}
 