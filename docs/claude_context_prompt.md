**PROJECT: Fruit Retail & Wholesale POS System**

**WHAT THIS PROJECT IS:**
A Point of Sale system for fruit vendors that handles retail + wholesale transactions, inventory, billing, expenses, customer management, and reporting. It features role-based access control (Super Admin, Admin, Employee, Viewer) and supports multi-shop isolation.

**TECH STACK:**
- Frontend: Flutter (Dart) with GetX for state management.
- Backend/Business Logic: Firebase Cloud Functions (TypeScript).
- Database: Cloud Firestore.
- Authentication: Firebase Authentication.
- Storage: Firebase Storage (receipts/images).

**PROJECT FILE STRUCTURE:**
Frontend (`lib/`):
```text
lib/
├── core/ (audit, auth, rbac, services, utils)
├── data/ (models, repositories, services, canonical_enums.dart)
├── modules/
│   ├── admin/
│   ├── authentication/
│   ├── expenses/
│   ├── inventory/
│   ├── orders/
│   ├── pos/
│   ├── products/
│   ├── reports/
│   ├── settings/
│   └── super_admin/
├── routing/ (app_routes.dart, role_based_router.dart, route_guard.dart)
├── theme/
└── main.dart
```

Backend (`firebase/functions/src/`):
```text
src/
├── auth/ (auth_audit.ts, createAdminUser.ts, loginLockout.ts, session.ts)
├── expenses/ (expenseAudit.ts)
├── inventory/ (adjustStock.ts, inventoryLogs.ts)
├── orders/ (cancelOrder.ts, confirmOrder.ts)
├── products/ (onPriceChange.ts)
├── types/ (canonicalEnums.ts, index.ts)
├── utils/ (auditLogger.ts, inventoryLogs.ts, roleValidation.ts, validation.ts)
└── index.ts
```

**DOCUMENTATION / SPECS:**
- Requirements: Strict adherence to SRS, Detailed Requirements, Technical Requirements, and module-wise prompts.
- All financial and inventory mutations must pass through Cloud Functions.
- Firestore Security Rules enforce Deny-by-Default and role/shop-based access.

**THE COMPLIANCE BUGS:**
There are several critical compliance and logic issues identified in the latest implementation audit:
1. **Role/status string mismatch (Firestore vs app vs Cloud Functions):**
   Firestore rules use `'Super Admin'`, `'Admin'`, `'Employee'`, `'Viewer'`, `'Active'`. 
   Flutter and `employee_form_screen` write lowercase values (`'super_admin'`, `'employee'`, `'active'`). 
   Cloud Functions `roleValidation.ts` checks for `'active'` (lowercase). 
   This causes permission checks to fail unexpectedly.
2. **Order confirmation flow broken:** 
   `payment_screen.dart` creates orders with `paymentStatus: 'pending'`. 
   The `confirmOrder` Cloud Function requires `order.paymentStatus === 'success'` and rejects the transaction.
3. **`confirmOrder` call missing `shopId`:** 
   The Flutter client fails to pass the `shopId` to the `confirmOrder` Cloud Function, causing immediate validation failure.
4. **Expense create/update bypasses Cloud Functions:** 
   Expenses are written directly to Firestore via `ExpenseScreen` instead of using the required Cloud Functions (`createExpense`, `updateExpense`), bypassing mandatory role validation and actor-specific auditing.
5. **No auth audit from client:** 
   The client does not call the required auth audit Cloud Functions (`logLoginSuccess`, `logLoginFailure`, `logLogout`), meaning authentication events are not logged properly.
6. **Employee daily sales query uses wrong status:** 
   `daily_sales_summary_screen.dart` queries `orderStatus == 'confirmed'`, but `confirmOrder` correctly sets the status to `'locked'`.

**WHAT NEEDS TO BE FIXED:**
1. Standardize role and status strings across Firestore Rules, Flutter app, and Cloud Functions (e.g., use `'Employee'`, `'Active'`).
2. Update the Flutter `payment_screen.dart` to set `paymentStatus: 'success'` before calling `confirmOrder`.
3. Pass `shopId` in the `confirmOrder` callable request from Flutter.
4. Refactor `ExpenseScreen` to use Cloud Functions for creating/updating expenses instead of direct Firestore writes.
5. Invoke `logLoginSuccess`, `logLoginFailure`, and `logLogout` callables from `auth_controller.dart` and `login_screen.dart`.
6. Fix the query in `daily_sales_summary_screen.dart` to use `orderStatus == 'locked'`.

**WHAT CORRECT BEHAVIOR LOOKS LIKE:**
- Valid users should not be blocked due to casing mismatches in roles or statuses.
- Upon successful payment, orders should be successfully confirmed via the `confirmOrder` Cloud Function, deducting inventory and logging audits correctly.
- Expenses must be routed through Cloud Functions and correctly audited with the real user ID.
- All authentication events must be logged to Firestore.
- Employee daily sales must accurately reflect locked/completed orders.

**ADDITIONAL CONTEXT:**
- The architecture requires that UI writes to Firestore directly only for non-sensitive data. All financial (orders, expenses) and inventory data MUST go through Cloud Functions.
- Security Rules are fully functional but rely on correct string values to authorize users.
