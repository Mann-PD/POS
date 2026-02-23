/**
 * Validation utilities for Cloud Functions
 * Enforces all business rules from requirements
 */

import { PaymentMethod, MeasurementType } from '../types';

/**
 * Validates that a value is a non-empty string
 */
export function validateRequiredString(value: any, fieldName: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${fieldName} is required and must be a non-empty string`);
  }
  return value.trim();
}

/**
 * Validates that a value is a positive number
 */
export function validatePositiveNumber(value: any, fieldName: string): number {
  if (typeof value !== 'number' || isNaN(value) || value <= 0) {
    throw new Error(`${fieldName} must be a positive number`);
  }
  return value;
}

/**
 * Validates that a value is a non-negative number
 */
export function validateNonNegativeNumber(value: any, fieldName: string): number {
  if (typeof value !== 'number' || isNaN(value) || value < 0) {
    throw new Error(`${fieldName} must be a non-negative number`);
  }
  return value;
}

/**
 * Validates shopId
 */
export function validateShopId(shopId: any): string {
  return validateRequiredString(shopId, 'shopId');
}

/**
 * Validates userId
 */
export function validateUserId(userId: any): string {
  return validateRequiredString(userId, 'userId');
}

/**
 * Validates email format
 */
export function validateEmail(email: string): string {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new Error('Invalid email format');
  }
  return email;
}

/**
 * Validates mobile number format (basic validation)
 */
export function validateMobile(mobile: string): string {
  const mobileRegex = /^[0-9]{10,15}$/;
  if (!mobileRegex.test(mobile.replace(/\D/g, ''))) {
    throw new Error('Invalid mobile number format');
  }
  return mobile.replace(/\D/g, '');
}

/**
 * Validates payment method
 */
export function validatePaymentMethod(method: any): PaymentMethod {
  if (!Object.values(PaymentMethod).includes(method)) {
    throw new Error(`Invalid payment method: ${method}`);
  }
  return method as PaymentMethod;
}

/**
 * Validates measurement type
 */
export function validateMeasurementType(type: any): MeasurementType {
  if (!Object.values(MeasurementType).includes(type)) {
    throw new Error(`Invalid measurement type: ${type}`);
  }
  return type as MeasurementType;
}

/**
 * Validates that customer details are present
 */
export function validateCustomerDetails(customerId: string, name: string, mobile: string): void {
  validateRequiredString(customerId, 'customerId');
  validateRequiredString(name, 'Customer name');
  validateMobile(mobile);
}
