# Fruit POS System — Audit Report vs. Documentation

**Audit date:** February 24, 2025  
**Reference documents:**
- Software Requirements Specification (SRS)
- Requirement in Detail
- TECHNICAL REQUIREMENTS IN DETAIL
- Prompt-Based Model — Module-Wise A (Module-Wise AI Prompts)

**Verdict:** The app is **partially compliant**. Core flows (auth, POS billing, mandatory customer, payment, inventory, expenses, RBAC in backend) work and align with the docs, but several requirements are missing or inconsistent. **It is not fully working as specified** until the gaps below are addressed.

---

## 1. Executive Summary

| Area | Status | Notes |
|------|--------|--------|
| Authentication & role-based redirection | ✅ Mostly OK | Login, status, role, shop validation; logout audit. Viewer route and login-failure audit wrong. |
| RBAC (Firestore + Cloud Functions) | ✅ Strong | Deny-by-default, role + shopId, orders/customers/audit immutable. |
| POS billing (Employee) | ✅ OK | Product selection, quantity/weight, cart, mandatory customer, payment, receipt, confirmOrder. |
| Customer mandatory | ✅ OK | Name + mobile required; cannot proceed without customer details. |
| Payments | ✅ OK | Cash, UPI, Card; mandatory; no partial payments; confirmOrder CF. |
| Products & inventory | ✅ OK | CRUD (Admin/Super); stock deduction via CF; low-stock in rules. Product status casing inconsistent. |
| Orders | ✅ OK | Create by Employee only; confirmOrder locks and deducts stock; no delete. |
| Expenses | ✅ OK | Create/update via callables only; Employee no access; audit. |
| Reports & Analytics | ❌ Not done | Placeholder screen only. |
| Viewer role | ❌ Wrong | Should land on Reports; currently lands on POS Home. |
| Order history (Admin) | ❌ Placeholder | Screen exists but "Full implementation pending". |
| Audit logging | ⚠️ Partial | Login success/logout via logAuthEvent; **failed login not logged** (wrong callable). |
| Role/status casing | ⚠️ Risk | Flutter "Super Admin" vs Firestore "SuperAdmin"; product "Active" vs "active". |
| Barcode/QR scan | ❌ Missing | Doc mentions scan option on POS Home; not implemented. |

---

## 2. What Matches the Documents

### 2.1 Authentication (Requirement in Detail §7–8, §14)

- Firebase Auth for login/logout.
- Role and shopId from Firestore; account status (Active/Inactive/Suspended) enforced; no access without auth.
- Role-based redirection: Employee → POS Home, Admin → Admin Dashboard, Super Admin → Super Admin Dashboard.
- No self-registration; controlled user creation (Admin creates Employee, Super Admin creates Admin).
- Forgot password screen present.
- Session bound to user; logout calls `logAuthEvent` (LOGOUT) then signs out.
- Bootstrap first user (bootstrapFirstUser) for recovery when no active user.

### 2.2 Mandatory Customer & Order Flow (Requirement in Detail §19, §34.4)

- Cart → Customer screen (mandatory) → Payment → Receipt.
- Customer name and mobile required; validated; cannot skip.
- Customer create/lookup by mobile; order linked to customerId; customer deletion forbidden in Firestore.

### 2.3 POS Billing (Requirement in Detail §15–22)

- POS Home: categories, search, product grid, cart FAB.
- Quantity/weight dialog: kg/gm (decimal) and piece/box (integer); live price; stock check.
- Cart: list, adjust qty, remove; proceed to checkout → Customer screen.
- Payment: Cash, UPI, Card; mandatory selection; confirm creates order + order_items then calls `confirmOrder`.
- Receipt: order ID, date/time, items, total, payment method, customer name/mobile.
- Daily sales summary: employee’s own orders only (employeeId + shopId), date filter, locked orders only.
- Out-of-stock/disabled products not sellable (checks in POS Home and quantity dialog).

### 2.4 Backend Enforcement (Technical Requirements §4–6)

- **Firestore rules:** Deny by default; role + shopId; only Employee can create orders/order_items; orders/order_items/customers/audit_logs/inventory_logs immutable or append-only; expenses write disabled (callables only).
- **confirmOrder:** Employee only; validates order (pending, Success); deducts stock in transaction; locks order; writes inventory_logs and audit_logs.
- **cancelOrder:** Admin/Super only; cancels pending only; audit log.
- **Expenses:** createExpense/updateExpense/createOrUpdateExpense with Admin/Super and amount > 0; Firestore rules block direct client writes.
- **Auth audit:** logAuthEvent (LOGIN_SUCCESS, LOGOUT); onUserStatusChange trigger.

### 2.5 Admin & Super Admin

- Admin Dashboard: Products, Inventory, Employees, Expenses, Reports (nav only).
- Super Admin Dashboard and user management (status Active/Inactive/Suspended).
- Admin cannot create orders (only Employee can); enforced by Firestore and confirmOrder.
- Expense creation only via callables; Employee has no expense access.

### 2.6 Data Integrity

- Orders not deletable; customers not deletable; products not deletable (delete: if false).
- Order locked after confirmOrder; no edit after confirmation.
- Price snapshot in order_items; stock updated only in confirmOrder transaction.

---

## 3. Gaps and Non-Compliance

### 3.1 Viewer role landing (Requirement in Detail §8.5, §15.4)

- **Requirement:** Viewer / Accountant → Reports & Analytics Dashboard (read-only).
- **Current:** `viewerDashboard` in `main.dart` and `RoleBasedRouter` sends Viewer to **POS Home** (`PosHomeScreen`).
- **Fix:** Add a read-only Reports dashboard (or reuse Reports screen) and set `viewerDashboard` to that route so Viewer never lands on POS.

### 3.2 Reports & Analytics (Requirement in Detail §31, §22)

- **Requirement:** Sales reports (daily/weekly/monthly), product-wise, employee-wise, expense reports; read-only.
- **Current:** `ReportsDashboard` is a placeholder (“Full implementation pending”).
- **Fix:** Implement real report screens (sales, product, employee, expense) with read-only, shop-scoped data.

### 3.3 Order history for Admin (Requirement in Detail §30)

- **Requirement:** Admin views order history; cancel order (with audit).
- **Current:** `OrderHistoryScreen` is a placeholder.
- **Fix:** Implement order list (shop-scoped) with view details and cancel (via cancelOrder) for pending orders.

### 3.4 Failed login audit (Requirement in Detail §14.1, §8.7)

- **Requirement:** Failed login attempts SHALL be logged.
- **Current:** On login failure, app calls `logAuthEvent` with `action: 'LOGIN_FAILURE'`. `logAuthEvent` **requires an authenticated user**, so the call fails and failed attempts are not logged.
- **Fix:** On login failure, call `logLoginFailure` (no auth required) with email/phone and error message instead of `logAuthEvent`.

### 3.5 Role string consistency (Technical Requirements, Firestore rules)

- **Requirement:** Single canonical role format for rules and app.
- **Current:** Firestore rules use `'SuperAdmin'` (no space); Flutter `UserModel` normalizes to `'Super Admin'` only for `'super admin'` / `'super_admin'`, not for `'superadmin'`. So if Firestore has `role: 'SuperAdmin'`, Flutter keeps `'SuperAdmin'`, and the check `user.role != 'Super Admin'` in `main.dart`/`auth_controller.dart` requires shopId even for Super Admin (wrong for empty shopId).
- **Fix:** Either (a) normalize `'SuperAdmin'` → `'Super Admin'` in `UserModel._normalizeRole` and ensure Super Admin is exempt from shopId when role is “Super Admin”, or (b) store and use one canonical form everywhere (e.g. `SuperAdmin` in Firestore and in app checks).

### 3.6 Product status casing (ProductModel vs Firestore)

- **Current:** Firestore and product form use `'active'` / `'inactive'`; `ProductModel.isActive` uses `status == 'Active'`. So when status is `'active'`, `isActive` is false. POS Home uses `product.status != 'active'` and queries `status == 'active'`, so listing is consistent, but any use of `product.isActive`/`isAvailable` can be wrong.
- **Fix:** Use one convention (e.g. lowercase in Firestore and in ProductModel) and make `ProductModel.isActive` use case-insensitive compare or a single canonical value.

### 3.7 Barcode / QR scan (Requirement in Detail §16.2–16.3)

- **Requirement:** “Barcode / QR scan option” on POS Home.
- **Current:** Not implemented.
- **Fix:** Add scan option (e.g. barcode/QR) that resolves to product and adds to cart, or explicitly mark as out of scope for current phase.

### 3.8 Optional: Session timeout, concurrent login (Requirement in Detail §12.2–12.3)

- Session timeout and concurrent-login rules are described in the docs but not implemented. Note as future work unless required for release.

---

## 4. Module-by-Module Checklist

| Module | Requirement | Implemented | Notes |
|--------|-------------|-------------|--------|
| Auth | Login with email/password | ✅ | |
| Auth | Role + shop + status validation | ✅ | |
| Auth | Role-based redirection | ⚠️ | Viewer → POS instead of Reports |
| Auth | Logout + audit | ✅ | logAuthEvent(LOGOUT) |
| Auth | Failed login audit | ❌ | logAuthEvent used; should use logLoginFailure |
| Auth | Forgot password | ✅ | |
| Auth | No self-registration | ✅ | |
| POS | Product list + categories + search | ✅ | |
| POS | Quantity/weight (kg, gm, piece, box) | ✅ | |
| POS | Cart + edit + remove | ✅ | |
| POS | Mandatory customer (name + mobile) | ✅ | |
| POS | Payment methods (Cash, UPI, Card) | ✅ | |
| POS | Confirm order → receipt | ✅ | confirmOrder CF |
| POS | Daily sales (own only) | ✅ | |
| POS | Barcode/QR scan | ❌ | |
| Products | CRUD (Admin/Super) | ✅ | |
| Products | Price > 0; measurement type | ✅ | |
| Products | No product delete | ✅ | Rules |
| Products | Status active/disabled | ✅ | Casing inconsistency |
| Inventory | Stock deduction on confirm | ✅ | CF only |
| Inventory | No negative stock | ✅ | CF |
| Orders | Create by Employee only | ✅ | Rules + CF |
| Orders | No delete; no edit after lock | ✅ | |
| Orders | Cancel (Admin/Super) + audit | ✅ | cancelOrder |
| Orders | Order history (Admin) | ❌ | Placeholder |
| Customers | Mandatory name + mobile | ✅ | |
| Customers | No customer delete | ✅ | Rules |
| Expenses | Admin/Super only; via CF | ✅ | |
| Expenses | Amount > 0; audit | ✅ | |
| Expenses | No future-dated (CF) | ✅ | validation |
| Reports | Sales/product/employee/expense | ❌ | Placeholder |
| Reports | Viewer read-only dashboard | ❌ | Viewer sent to POS |
| Audit logs | Append-only; no edit/delete | ✅ | Rules + CF |
| Audit logs | Login/logout/order/expense/user | ✅ | Login failure missing |
| Settings | Shop/system scope | ✅ | Rules |
| Employee mgmt | Create/activate/deactivate | ✅ | |
| Super Admin | Admin mgmt; global view | ✅ | |

---

## 5. Conclusion and Recommendations

- **Conclusion:** The system is **not fully working as per the documents**. Core POS, auth, RBAC, mandatory customer, payments, and backend enforcement are in place and align with the SRS and Requirement in Detail. Several important items are missing or incorrect: Viewer landing, Reports implementation, Order history, failed login audit, and optional scan/UX items.
- **Recommendations (priority):**
  1. **High:** Send Viewer to Reports dashboard (read-only), not POS Home.
  2. **High:** Log failed logins via `logLoginFailure` (do not use `logAuthEvent` for failures).
  3. **High:** Implement Reports & Analytics (sales, product, employee, expense) with shop-scoped, read-only data.
  4. **High:** Implement Order History for Admin (list, detail, cancel pending via cancelOrder).
  5. **Medium:** Unify role string (Super Admin vs SuperAdmin) and product status casing (Active vs active) between Flutter and Firestore.
  6. **Lower:** Add barcode/QR scan on POS Home if in scope; document session timeout and concurrent login as future work.

After the high-priority fixes and (if desired) the medium ones, the app can be considered **fully working** relative to the referenced documentation.
