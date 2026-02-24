/**
 * Canonical enum definitions for Fruit POS System.
 * MUST match Flutter lib/data/canonical_enums.dart and Firestore rules exactly.
 * No additional values allowed. Reject unknown values.
 */

/** Role. Firestore: "SuperAdmin" | "Admin" | "Employee" | "Viewer" */
export enum Role {
  SuperAdmin = 'SuperAdmin',
  Admin = 'Admin',
  Employee = 'Employee',
  Viewer = 'Viewer',
}

/** Account status. Firestore: "Active" | "Inactive" | "Suspended" */
export enum AccountStatus {
  Active = 'Active',
  Inactive = 'Inactive',
  Suspended = 'Suspended',
}

/** Order status. Firestore: "pending" | "locked" | "cancelled" */
export enum OrderStatus {
  pending = 'pending',
  locked = 'locked',
  cancelled = 'cancelled',
}

/** Payment status. Firestore: "Success" | "Pending" | "Failed" */
export enum PaymentStatus {
  Success = 'Success',
  Pending = 'Pending',
  Failed = 'Failed',
}

const ROLE_VALUES: readonly string[] = Object.values(Role);
const ACCOUNT_STATUS_VALUES: readonly string[] = Object.values(AccountStatus);
const ORDER_STATUS_VALUES: readonly string[] = Object.values(OrderStatus);
const PAYMENT_STATUS_VALUES: readonly string[] = Object.values(PaymentStatus);

/**
 * Returns true only if value is a canonical Role string. Rejects unknown values.
 */
export function isValidRole(value: unknown): value is Role {
  return typeof value === 'string' && ROLE_VALUES.includes(value);
}

/**
 * Returns true only if value is a canonical AccountStatus string. Rejects unknown values.
 */
export function isValidStatus(value: unknown): value is AccountStatus {
  return typeof value === 'string' && ACCOUNT_STATUS_VALUES.includes(value);
}

/**
 * Returns true only if value is a canonical OrderStatus string. Rejects unknown values.
 */
export function isValidOrderStatus(value: unknown): value is OrderStatus {
  return typeof value === 'string' && ORDER_STATUS_VALUES.includes(value);
}

/**
 * Returns true only if value is a canonical PaymentStatus string. Rejects unknown values.
 */
export function isValidPaymentStatus(value: unknown): value is PaymentStatus {
  return typeof value === 'string' && PAYMENT_STATUS_VALUES.includes(value);
}
