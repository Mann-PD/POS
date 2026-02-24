# Role Pipelines — Fruit POS System

This document describes the **pipeline** (flow from login to every screen and action) for each role in the app.

---

## 1. Entry point (all roles)

```
┌─────────────────┐
│   Login Screen  │  ← Email + Password
└────────┬────────┘
         │ success
         ▼
┌─────────────────┐
│   AuthWrapper   │  ← Fetches user from Firestore, validates status/role/shopId
└────────┬────────┘
         │
         │ RoleBasedRouter.getInitialRoute(role)
         ▼
    ┌────┴────┬────────────┬──────────────┐
    ▼         ▼            ▼              ▼
 Employee   Admin   Super Admin    Viewer
    │         │            │              │
    ▼         ▼            ▼              ▼
  (see §2)  (see §3)   (see §4)      (see §5)
```

**Routes (from `main.dart`):**

| Role         | Route constant              | Target screen        |
|-------------|-----------------------------|----------------------|
| Employee    | `employeeDashboard`          | `PosHomeScreen`      |
| Admin       | `adminDashboard`            | `AdminDashboard`     |
| Super Admin | `superAdminDashboard`        | `SuperAdminDashboard`|
| Viewer      | `viewerDashboard`            | `PosHomeScreen` *    |

\* Per docs, Viewer should land on **Reports & Analytics** (read-only); currently app sends Viewer to POS Home.

---

## 2. Employee pipeline (POS user / cashier)

**Landing:** POS Home (`PosHomeScreen`)

```
                    ┌──────────────────────┐
                    │     POS Home          │
                    │  • Categories         │
                    │  • Search             │
                    │  • Product grid       │
                    │  • Cart FAB           │
                    └──────┬───────────┬────┘
                           │           │
         Tap product       │           │  Tap bar chart icon
         (quantity dialog) │           │
                           ▼           ▼
                    ┌────────────┐  ┌─────────────────────┐
                    │  Cart      │  │ Daily Sales Summary  │
                    │  (review)  │  │ (own orders, date)   │
                    └──────┬─────┘  └─────────────────────┘
                           │
                    "Proceed to Checkout"
                           ▼
                    ┌────────────────────┐
                    │ Customer Details   │  ← Mandatory: name + mobile
                    └──────┬─────────────┘
                           │
                    "Proceed to Payment"
                           ▼
                    ┌────────────────────┐
                    │ Payment            │  ← Cash / UPI / Card
                    │ "Confirm Order"     │
                    └──────┬─────────────┘
                           │  confirmOrder CF
                           ▼
                    ┌────────────────────┐
                    │ Receipt            │  ← Order ID, items, total, customer
                    │ "Done" → back      │
                    └────────────────────┘
```

**Actions:**

- **POS Home:** Browse products, search, filter by category, add to cart (quantity/weight dialog), open cart, open Daily Sales Summary, logout.
- **Cart:** Change quantity, remove item, proceed to checkout (→ Customer screen).
- **Customer:** Enter name + mobile (required), proceed to payment.
- **Payment:** Select method, confirm order (creates order + items, calls `confirmOrder` CF, then receipt).
- **Receipt:** View receipt, “Done” returns to POS flow.
- **Daily Sales Summary:** View own orders for selected date (read-only).

**Restrictions (enforced by UI + Firestore/CF):** No products/inventory/expenses/employees/reports management; no price change; no order cancel.

---

## 3. Admin pipeline (shop owner / manager)

**Landing:** Admin Dashboard (`AdminDashboard`)

```
                    ┌──────────────────────┐
                    │   Admin Dashboard     │
                    │   (single shop)       │
                    └──────┬───────────────┘
                           │
         ┌─────────────────┼─────────────────┬──────────────────┐
         ▼                 ▼                 ▼                  ▼
  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
  │  Products   │  │  Inventory  │  │  Employees  │  │  Expenses   │
  │  (CRUD)     │  │  (view/adj) │  │  (CRUD,     │  │  (add/edit  │
  │             │  │             │  │   activate) │  │   via CF)   │
  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
         │
         └──────────────────────┬───────────────────────────────────┘
                                 ▼
                         ┌─────────────┐
                         │  Reports &  │  ← Placeholder in current app
                         │  Analytics  │
                         └─────────────┘
```

**Actions:**

- **Admin Dashboard:** Navigate to Products, Inventory, Employees, Expenses, Reports; logout.
- **Products:** List/add/edit/disable products (shop-scoped); no delete (rules).
- **Inventory:** View/update stock (shop-scoped); low-stock view.
- **Employees:** List/add/edit employees (shop-scoped); activate/deactivate; no delete for Admin (Super Admin only in rules).
- **Expenses:** List; add/edit via Cloud Functions only (createExpense/updateExpense); no direct Firestore write.
- **Reports:** Currently placeholder (“Full implementation pending”).

**Restrictions:** No POS billing (no order creation); no system/super-admin settings; no Admin creation; no order delete.

---

## 4. Super Admin pipeline (system owner / platform admin)

**Landing:** Super Admin Dashboard (`SuperAdminDashboard`)

```
                    ┌──────────────────────┐
                    │ Super Admin Dashboard │
                    │  (system-wide)        │
                    └──────┬───────────────┘
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
     ┌─────────────────┐         ┌─────────────┐
     │ User Management │         │   Logout    │
     │ • List all users│         └─────────────┘
     │ • Set status:   │
     │   Active /      │
     │   Inactive /    │
     │   Suspended     │
     └─────────────────┘
```

**Actions:**

- **Super Admin Dashboard:** Open User Management; logout.
- **User Management:** See all users (all shops); change status to Active, Inactive, or Suspended (Firestore update). No create/edit of user details in this screen (only status).

**Restrictions:** No POS billing; no editing of historical sales/orders; no product/inventory/expense management in current UI (only user status). Backend allows Super Admin to manage all collections; UI currently exposes only User Management.

---

## 5. Viewer pipeline (accountant / read-only)

**Landing (current app):** Same as Employee → **POS Home** (`PosHomeScreen`).

**Intended (per docs):** Reports & Analytics dashboard (read-only).

```
  Current (wrong):     Intended (per docs):
  Viewer → POS Home    Viewer → Reports & Analytics (read-only)
                       • Sales reports
                       • Order history
                       • Expense summaries
```

So in the **current** app, Viewer uses the same pipeline as Employee (POS Home → Cart → Customer → Payment → Receipt, plus Daily Sales). Per requirement docs, Viewer should **not** do POS; they should only see reports. Fix: point `viewerDashboard` to a read-only Reports screen.

---

## 6. Summary table

| Role         | Landing screen       | Next screens / actions |
|-------------|----------------------|-------------------------|
| **Employee**| POS Home             | Cart → Customer → Payment → Receipt; Daily Sales Summary; Logout |
| **Admin**   | Admin Dashboard      | Products, Inventory, Employees, Expenses, Reports; Logout |
| **Super Admin** | Super Admin Dashboard | User Management (status only); Logout |
| **Viewer**  | POS Home (current)   | Same as Employee today; should be Reports only (read-only) |

---

## 7. Logout (all roles)

- **Employee (POS):** AppBar logout icon → confirm dialog → `AuthController.signOut()` (calls `logAuthEvent` CF) → `pushNamedAndRemoveUntil('/login')`.
- **Admin:** Same (confirm dialog → signOut → login).
- **Super Admin:** Logout button → signOut → login (no dialog in current code).
- **Viewer:** Same as Employee (uses POS Home).

All roles end at **Login** after logout; no role switching without logging in again.
