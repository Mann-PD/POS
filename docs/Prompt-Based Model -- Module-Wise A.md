**Prompt-Based Model -- Module-Wise AI Prompts for POS Implementation**

------------------------------------------------------------------------

**1. Usage Instructions**

This document is a **prompt library** intended exclusively for
**AI-assisted code generation** using tools such as Cursor AI,
Copilot-style agents, or autonomous coding models.

**Mandatory Source of Truth**

This document is derived **strictly and exclusively** from:

1.  Software Requirements Specification (SRS)

2.  Requirement in Detail -- Fruit Retail & Wholesale POS System

3.  Technical Requirements in Detail -- Firebase + Flutter

These documents are **immutable** and **authoritative**.

**Mandatory Workflow**

- Use this document as **Prompt-Based Model ONLY\
  \**

- For each module:

  - Copy the module prompt **verbatim\
    \**

  - Paste it into the coding AI

  - Generate implementation code strictly based on the prompt

- If ambiguity occurs:

  - **DO NOT GUESS\
    \**

  - Resolve conflicts in this order:

    1.  Requirement in Detail

    2.  Technical Requirements

    3.  SRS

- This document **MUST NOT be edited** during implementation

------------------------------------------------------------------------

**2. Global System Context Prompt (MASTER PROMPT)**

**SYSTEM PROMPT --- MUST BE PROVIDED TO THE AI BEFORE ANY MODULE**

You are implementing a **Fruit Retail & Wholesale POS System**.

The system enforces **strict role-based access control** with exactly
four roles:

- Super Admin

- Admin

- Employee

- Viewer

**Firebase is the ONLY backend**.\
**Cloud Firestore** is the ONLY database.\
**Cloud Functions** enforce all critical business logic.

The system follows **deny-by-default security**.\
Any action not explicitly permitted is forbidden.

Orders, customers, audit logs, inventory logs, and historical pricing
are **immutable**.

Employees perform **POS billing only**.\
Admins manage **shop-level operations only**.\
Super Admins manage **system-level governance only**.

Mandatory customer details, payment finalization, inventory integrity,
audit logging, and role isolation are **non-negotiable**.

UI logic **must never** bypass backend enforcement.

You must implement **exactly what is defined** --- no assumptions, no
extensions, no simplifications.

**3. Module-Wise Implementation Prompts**

------------------------------------------------------------------------

**3.1 Authentication & Account Lifecycle**

**Objective**

Implement secure user authentication, identity verification, role
detection, account lifecycle control, and session management.

**MUST Implement**

- Firebase Authentication for login/logout

- Role resolution from Firestore users collection

- Account states:

  - Active (login allowed)

  - Inactive (login blocked)

  - Suspended (temporarily blocked)

- Controlled user creation:

  - No public registration

  - Admin creates Employees

  - Super Admin creates Admins

- Password reset via registered email

- Secure session lifecycle:

  - Session creation

  - Session expiration

  - Manual logout

**MUST Enforce**

- Role-based redirection after authentication

- One immutable role per user

- Shop assignment validation (except Super Admin)

- Session binding to:

  - userId

  - role

  - shopId

- Audit logging for:

  - Login success/failure

  - Logout

  - Account creation

  - Account status change

  - Password reset

**MUST NOT Allow**

- Self-registration

- Role switching

- Login with inactive/suspended account

- Access without authentication

**Backend Enforcement**

- Firebase Auth for identity

- Firestore validation for role & status

- Cloud Functions for audit logging

**Data Integrity Guarantees**

- userId immutable

- role immutable

- Authentication history preserved permanently

------------------------------------------------------------------------

**3.2 Role-Based Access Control (RBAC)**

**Objective**

Enforce strict RBAC across all system modules at UI and backend layers.

**MUST Implement**

- Role validation on **every** read/write request

- Shop-level data isolation using shopId

- Consistent permission enforcement across modules

**MUST Enforce**

- Deny-by-default policy

- Explicit allow-only permissions

- Role + shopId mandatory in every query

- Permission checks in Cloud Functions

**MUST NOT Allow**

- Cross-role access

- Cross-shop access (except Super Admin)

- Deep-link or direct access bypass

**Backend Enforcement**

- Firestore Security Rules

- Cloud Function role validation

**Data Integrity Guarantees**

- All permission violations logged

- Unauthorized operations blocked before execution

------------------------------------------------------------------------

**3.3 Employee POS Billing**

**Objective**

Enable controlled, employee-only sales transaction processing.

**MUST Implement**

- Order creation

- Product selection

- Quantity / weight handling

- Mandatory customer capture

- Payment method selection

- Order confirmation

- Receipt generation

- Employee's own sales summary

**MUST Enforce**

- Weight-based vs unit-based rules

- Stock availability checks

- Mandatory customer details

- Payment confirmation before order completion

- Order immutability after confirmation

**MUST NOT Allow**

- Admin or Super Admin billing

- Discounts

- Price overrides

- Order edits after payment

**Backend Enforcement**

- Order confirmation via Cloud Function

- Inventory deduction after confirmation

**Data Integrity Guarantees**

- Orders immutable

- Inventory updated atomically

------------------------------------------------------------------------

**3.4 Customer Management**

**Objective**

Maintain mandatory customer data permanently linked to orders.

**MUST Implement**

- Customer creation during billing

- Customer lookup for repeat orders

- Permanent order-customer linkage

**MUST Enforce**

- Mandatory name and mobile

- Valid mobile format

- Shop-level customer isolation

**MUST NOT Allow**

- Customer deletion

- Order without customer

**Backend Enforcement**

- Firestore rules preventing deletion

**Data Integrity Guarantees**

- Customer history preserved permanently

------------------------------------------------------------------------

**3.5 Product Management**

**Objective**

Manage sellable products with strict pricing and measurement rules.

**MUST Implement**

- Create, edit, disable products

- Measurement type assignment

- Category linkage (if applicable)

**MUST Enforce**

- Price \> 0

- Measurement type immutable after first sale

- Disabled products cannot be sold

**MUST NOT Allow**

- Employee modifications

- Admin deletion of products with history

**Backend Enforcement**

- Firestore rules

- Cloud Function audit logging for price changes

**Data Integrity Guarantees**

- Historical pricing preserved

------------------------------------------------------------------------

**3.6 Inventory Management**

**Objective**

Ensure accurate real-time stock control.

**MUST Implement**

- Automatic stock deduction

- Low-stock alerts

- Inventory change logs

**MUST Enforce**

- Stock ≥ 0

- Deduction only after confirmed order

**MUST NOT Allow**

- Employee manual stock changes

**Backend Enforcement**

- Cloud Functions only

**Data Integrity Guarantees**

- Inventory logs immutable

------------------------------------------------------------------------

**3.7 Orders & Order Items**

**Objective**

Store complete, auditable order records.

**MUST Implement**

- Orders collection

- Order items with price snapshots

**MUST Enforce**

- No deletion

- No modification after confirmation

**MUST NOT Allow**

- Admin or Super Admin order creation

**Backend Enforcement**

- Firestore immutability rules

**Data Integrity Guarantees**

- Full audit trail preserved

------------------------------------------------------------------------

**3.8 Payments & Order Finalization**

**Objective**

Secure and finalize payments.

**MUST Implement**

- Payment method selection

- Payment confirmation

- Receipt generation

**MUST Enforce**

- Payment before order confirmation

- No partial payments

**MUST NOT Allow**

- Failed-payment orders

**Backend Enforcement**

- confirmOrder Cloud Function

**Data Integrity Guarantees**

- Payment data immutable

------------------------------------------------------------------------

**3.9 Expense Management**

**Objective**

Track shop operational expenses.

**MUST Implement**

- Expense creation, update, view (role-based)

**MUST Enforce**

- Amount \> 0

- No future-dated expenses

**MUST NOT Allow**

- Employee access

- Admin deletion

**Backend Enforcement**

- Cloud Functions + audit logs

------------------------------------------------------------------------

**3.10 Reports & Analytics**

**Objective**

Provide read-only business insights.

**MUST Implement**

- Sales, product, employee, expense reports

**MUST Enforce**

- Read-only access

- Shop-level isolation

**MUST NOT Allow**

- Data modification

------------------------------------------------------------------------

**3.11 Employee Management**

**Objective**

Manage POS employees securely.

**MUST Implement**

- Create, activate, deactivate employees

**MUST Enforce**

- History preservation

**MUST NOT Allow**

- Admin deletion of employees

------------------------------------------------------------------------

**3.12 Admin Controls**

**Objective**

Enable shop-level management only.

**MUST Implement**

- Products

- Inventory

- Employees

- Expenses

- Reports

**MUST Enforce**

- No POS billing

------------------------------------------------------------------------

**3.13 Super Admin Controls**

**Objective**

Enable system-wide governance.

**MUST Implement**

- Admin management

- Global settings

- Cross-shop visibility

**MUST NOT Allow**

- POS billing

- Historical data modification

------------------------------------------------------------------------

**3.14 Audit Logs & Compliance**

**Objective**

Ensure complete traceability.

**MUST Implement**

- Append-only audit logs

**MUST Enforce**

- No edits

- No deletions

------------------------------------------------------------------------

**3.15 Settings & Configuration**

**Objective**

Configure operational rules.

**MUST Implement**

- Shop-level settings

- System-level settings

**MUST Enforce**

- Future-only application

- Audit logging

------------------------------------------------------------------------

**3.16 Multi-Shop Readiness (Architecture Only)**

**Objective**

Ensure future scalability.

**MUST Implement**

- shopId filtering everywhere

**MUST NOT Allow**

- Cross-shop access except Super Admin

------------------------------------------------------------------------

**4. Prompt Quality Rules**

- Generate **implementation code only\
  \**

- Never invent features

- Never relax validations

- Never bypass backend enforcement

- Never modify business rules

- Treat all prompts as **immutable contracts**