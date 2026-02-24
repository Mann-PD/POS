/**
 * Type definitions for POS System Cloud Functions
 * Based on TECHNICAL REQUIREMENTS IN DETAIL.md
 */

/** Canonical role values - must match Firestore rules and Flutter */
export enum UserRole {
  SUPER_ADMIN = 'SuperAdmin',
  ADMIN = 'Admin',
  EMPLOYEE = 'Employee',
  VIEWER = 'Viewer'
}

/** Canonical status values - must match Firestore rules and Flutter */
export enum UserStatus {
  ACTIVE = 'Active',
  INACTIVE = 'Inactive',
  SUSPENDED = 'Suspended'
}

export enum ProductStatus {
  ACTIVE = 'Active',
  DISABLED = 'disabled'
}

export enum OrderStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  LOCKED = 'locked',
  CANCELLED = 'cancelled'
}

/** paymentStatus.SUCCESS must match Firestore order create rule ('Success') */
export enum PaymentStatus {
  PENDING = 'pending',
  SUCCESS = 'Success',
  FAILED = 'failed'
}

export enum PaymentMethod {
  CASH = 'cash',
  UPI = 'upi',
  CARD = 'card'
}

export enum MeasurementType {
  KG = 'kg',
  GM = 'gm',
  PIECE = 'piece',
  BOX = 'box'
}

export interface User {
  userId: string;
  name: string;
  email: string;
  phone: string;
  role: UserRole;
  shopId: string;
  status: UserStatus;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface Product {
  productId: string;
  shopId: string;
  name: string;
  price: number;
  measurementType: MeasurementType;
  stock: number;
  status: ProductStatus;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface Order {
  orderId: string;
  shopId: string;
  customerId: string;
  employeeId: string;
  totalAmount: number;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  orderStatus: OrderStatus;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface OrderItem {
  orderItemId: string;
  orderId: string;
  productId: string;
  quantityOrWeight: number;
  priceSnapshot: number;
  totalPrice: number;
}

export interface Customer {
  customerId: string;
  shopId: string;
  name: string;
  mobile: string;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface Expense {
  expenseId: string;
  shopId: string;
  amount: number;
  description: string;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface InventoryLog {
  logId: string;
  productId: string;
  shopId: string;
  change: number;
  reason: string;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface AuditLog {
  logId: string;
  userId: string;
  role: string;
  shopId: string;
  action: string;
  entityType: string;
  entityId: string;
  timestamp: FirebaseFirestore.Timestamp;
}

export interface ConfirmOrderRequest {
  orderId: string;
  shopId: string;
  customerId: string;
  employeeId: string;
  orderItems: Array<{
    productId: string;
    quantityOrWeight: number;
  }>;
  paymentMethod: PaymentMethod;
  totalAmount: number;
}

export interface CancelOrderRequest {
  orderId: string;
  shopId: string;
  reason?: string;
}
