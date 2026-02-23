TECHNICAL REQUIREMENTS IN DETAIL

Fruit Retail & Wholesale POS System

Technology Stack: Flutter (Frontend) + Firebase (Backend)

1\. DOCUMENT PURPOSE & SCOPE

1.1 Purpose

This document defines HOW the Fruit Retail & Wholesale POS System is
implemented technically, based strictly and exclusively on Document #2
-- Requirement in Detail.

This document:

- Converts approved requirements into Firebase backend architecture

- Defines Firestore database schemas for all modules

- Defines role-based read/write data access

- Defines Cloud Function--based backend enforcement

- Defines Flutter ↔ Firebase responsibility boundaries

⚠️ This document does NOT introduce, modify, or remove any business
rule, feature, or permission.

1.2 Scope

This document:

- Implements ALL modules defined in Requirement in Detail

- Uses Firebase as the ONLY backend

- Covers backend implementation for:

  - Authentication & Authorization

  - Employee POS Billing

  - Products & Categories

  - Inventory Management

  - Orders & Order Items

  - Customers

  - Expenses

  - Audit Logs

  - Settings

- UI design, layouts, and screens are intentionally excluded

2\. OVERALL SYSTEM ARCHITECTURE

2.1 Architecture Style

The system follows a serverless client--server architecture with
centralized backend enforcement.

  ----------------------------------------------------------
  Layer            Technology         Responsibility
  ---------------- ------------------ ----------------------
  Client           Flutter            UI rendering & local
                                      state

  Authentication   Firebase           Identity verification
                   Authentication     

  Database         Cloud Firestore    Persistent business
                                      data

  Enforcement      Cloud Functions    Business rules &
                                      transactions

  Storage          Firebase Storage   Images & receipts

  Web Hosting      Firebase Hosting   Web admin & POS
  ----------------------------------------------------------

All critical operations are enforced at the backend.

2.2 Logical Module Separation

  ----------------------------------
  Module           Accessible By
  ---------------- -----------------
  Authentication   All roles

  Employee POS     Employee only

  Admin Management Admin & Super
                   Admin

  System Control   Super Admin only
  ----------------------------------

Backend enforcement cannot be bypassed by frontend logic.

3\. USER ROLES (SYSTEM-LEVEL)

  --------------------------------
  Role       Technical Scope
  ---------- ---------------------
  Super      System-wide,
  Admin      cross-shop

  Admin      Full control within
             one shop

  Employee   POS billing only

  Viewer     Read-only reporting
  --------------------------------

Roles are:

- Assigned once

- Stored in Firestore

- Immutable

- Enforced strictly at backend level

4\. MODULE-WISE FIRESTORE DATA SCHEMAS

(WITH ROLE-BASED READ / WRITE)

🔐 MODULE 1: USERS

Collection: users

Data Schema

  ------------------------------------
  Field       Type        Rule
  ----------- ----------- ------------
  userId      String      Immutable

  name        String      Mandatory

  email       String      Unique

  phone       String      Mandatory

  role        Enum        Immutable

  shopId      String      Required

  status      Enum        Active /
                          Inactive

  createdAt   Timestamp   Immutable
  ------------------------------------

Role-Based Read / Write

  ----------------------------------------
  Role       Read              Write
  ---------- ----------------- -----------
  Super      All               All
  Admin                        

  Admin      Employees (own    Employees
             shop)             

  Employee   Self only         ❌

  Viewer     ❌                ❌
  ----------------------------------------

🏪 MODULE 2: SHOPS

Collection: shops

  -----------------------
  Field       Type
  ----------- -----------
  shopId      String

  name        String

  status      Enum

  createdAt   Timestamp
  -----------------------

  ---------------------------
  Role       Read     Write
  ---------- -------- -------
  Super      All      All
  Admin               

  Admin      Own shop ❌

  Employee   ❌       ❌

  Viewer     ❌       ❌
  ---------------------------

📦 MODULE 3: PRODUCTS

Collection: products

  -------------------------------------------------
  Field             Type        Rule
  ----------------- ----------- -------------------
  productId         String      Immutable

  shopId            String      Mandatory

  name              String      Unique per shop

  price             Number      \> 0

  measurementType   Enum        Immutable after
                                first sale

  stock             Number      ≥ 0

  status            Enum        Active / Disabled

  createdAt         Timestamp   Immutable
  -------------------------------------------------

  --------------------------------
  Role       Read     Write
  ---------- -------- ------------
  Super      All      All
  Admin               

  Admin      Own shop Create /
                      Update

  Employee   Own shop ❌

  Viewer     Read     ❌
  --------------------------------

🗂️ MODULE 4: CATEGORIES

Collection: categories

  ------------------------
  Field        Type
  ------------ -----------
  categoryId   String

  shopId       String

  name         String

  status       Enum

  createdAt    Timestamp
  ------------------------

  ---------------------------
  Role       Read     Write
  ---------- -------- -------
  Super      All      All
  Admin               

  Admin      Own shop All

  Employee   Read     ❌

  Viewer     Read     ❌
  ---------------------------

🧾 MODULE 5: ORDERS

Collection: orders

  ----------------------------------------
  Field           Type        Rule
  --------------- ----------- ------------
  orderId         String      Immutable

  shopId          String      Mandatory

  customerId      String      Mandatory

  employeeId      String      Immutable

  totalAmount     Number      Calculated

  paymentMethod   Enum        Mandatory

  paymentStatus   Enum        Success only

  orderStatus     Enum        Locked

  createdAt       Timestamp   Immutable
  ----------------------------------------

🚫 Orders cannot be deleted or edited after confirmation.

  ------------------------------
  Role       Read      Write
  ---------- --------- ---------
  Super      All       ❌
  Admin                

  Admin      Own shop  ❌

  Employee   Own       Create
             orders    only

  Viewer     Read      ❌
  ------------------------------

📄 MODULE 6: ORDER ITEMS

Collection: order_items

  ---------------------------
  Field              Type
  ------------------ --------
  orderItemId        String

  orderId            String

  productId          String

  quantityOrWeight   Number

  priceSnapshot      Number

  totalPrice         Number
  ---------------------------

Immutable after order confirmation.

  -----------------------------
  Role       Read      Write
  ---------- --------- --------
  Super      All       ❌
  Admin                

  Admin      Own shop  ❌

  Employee   Own       Create
             orders    

  Viewer     Read      ❌
  -----------------------------

👥 MODULE 7: CUSTOMERS

Collection: customers

  ------------------------
  Field        Type
  ------------ -----------
  customerId   String

  shopId       String

  name         String

  mobile       String

  createdAt    Timestamp
  ------------------------

🚫 Customer deletion is prohibited.

  ----------------------------
  Role       Read     Write
  ---------- -------- --------
  Super      All      All
  Admin               

  Admin      Own shop All

  Employee   ❌       Create

  Viewer     Read     ❌
  ----------------------------

📉 MODULE 8: INVENTORY LOGS

Collection: inventory_logs

  -----------------------
  Field       Type
  ----------- -----------
  logId       String

  productId   String

  shopId      String

  change      Number

  reason      String

  createdAt   Timestamp
  -----------------------

Created only via Cloud Functions.

  ---------------------------
  Role       Read     Write
  ---------- -------- -------
  Super      All      ❌
  Admin               

  Admin      Own shop ❌

  Employee   ❌       ❌

  Viewer     ❌       ❌
  ---------------------------

💰 MODULE 9: EXPENSES

Collection: expenses

  -------------------------
  Field         Type
  ------------- -----------
  expenseId     String

  shopId        String

  amount        Number
                (\>0)

  description   String

  createdAt     Timestamp
  -------------------------

  --------------------------------
  Role       Read     Write
  ---------- -------- ------------
  Super      All      All
  Admin               

  Admin      Own shop Create /
                      Update

  Employee   ❌       ❌

  Viewer     Read     ❌
  --------------------------------

📜 MODULE 10: AUDIT LOGS

Collection: audit_logs

  ------------------------
  Field        Type
  ------------ -----------
  logId        String

  userId       String

  role         String

  shopId       String

  action       String

  entityType   String

  entityId     String

  timestamp    Timestamp
  ------------------------

Append-only.\
No update.\
No delete.

  ---------------------------
  Role       Read     Write
  ---------- -------- -------
  Super      All      ❌
  Admin               

  Admin      Own shop ❌

  Employee   ❌       ❌

  Viewer     ❌       ❌
  ---------------------------

⚙️ MODULE 11: SETTINGS

Collection: settings

  -----------------------
  Field       Type
  ----------- -----------
  settingId   String

  scope       shop /
              system

  key         String

  value       Any

  updatedAt   Timestamp
  -----------------------

  ----------------------------
  Role       Read     Write
  ---------- -------- --------
  Super      All      All
  Admin               

  Admin      Shop     Shop
             only     only

  Employee   ❌       ❌

  Viewer     ❌       ❌
  ----------------------------

5\. CLOUD FUNCTIONS (MANDATORY BACKEND ENFORCEMENT)

  -------------------------------------
  Function             Responsibility
  -------------------- ----------------
  confirmOrder         Inventory
                       deduction

  cancelOrder          Audit logging

  onPriceChange        Audit logging

  onExpenseChange      Audit logging

  onUserStatusChange   Audit logging
  -------------------------------------

All financial and inventory mutations must pass through Cloud Functions.

6\. FIRESTORE SECURITY RULES PHILOSOPHY

- Deny by default

- Role + shopId mandatory

- Orders, customers, audit logs immutable

- Employees have minimal write scope