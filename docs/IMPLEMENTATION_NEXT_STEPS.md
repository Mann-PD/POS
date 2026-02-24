# POS Project — Next-Step Execution Plan

This plan is derived from the four source documents in `docs/` and converts them into an execution sequence to finish the project without breaking the mandatory rules (RBAC, deny-by-default, Cloud Function enforcement, immutable order history, and shop isolation).

## Source Documents Reviewed
1. `docs/Software Requirements Specification.md`
2. `docs/Requirement in Detail.md`
3. `docs/TECHNICAL REQUIREMENTS IN DETAIL.md`
4. `docs/Prompt-Based Model -- Module-Wise A.md`

## Definition of Done (Project Completion)
A module is considered complete only when all four conditions are true:
- **UI Flow Complete** (screens and role-based navigation)
- **Backend Enforced** (critical write paths through Cloud Functions)
- **Rules Enforced** (Firestore rules deny-by-default and role/shop scoped)
- **Audit Complete** (security and business events logged with actor identity)

---

## Phase 1 — Stabilize Security-Critical Foundations (Do First)

### 1) Canonical enums and value contract (single source of truth)
**Why first:** Role/status/payment/order mismatches cause runtime denials and data integrity bugs.

**Actions**
- Create a canonical contract for:
  - `role`: `Super Admin | Admin | Employee | Viewer`
  - `status`: `Active | Inactive | Suspended`
  - `orderStatus`: `pending | locked | cancelled`
  - `paymentStatus`: `Success | Pending | Failed`
- Apply the same values in:
  - Flutter models/controllers
  - Cloud Functions validators/types
  - Firestore rules checks
- Add migration script/docs for existing documents with legacy lowercase values.

**Acceptance checks**
- A valid employee can login and reach POS.
- Employee data reads/writes are permitted only where required.
- No module fails because of enum casing mismatch.

### 2) Complete authentication audit trail
**Actions**
- Ensure client triggers Cloud Function audit callables for:
  - Login success
  - Login failure
  - Logout
  - Password reset requested/completed
- Persist actor and timestamp for each event.

**Acceptance checks**
- Every login attempt writes `audit_logs` entry.
- Logout and reset flows are traceable per user.

### 3) Lock all financial writes behind Cloud Functions
**Actions**
- Ensure order confirmation, expense create/update, inventory deduction, and status-changing admin actions are Cloud Function mediated.
- Remove/avoid direct Firestore writes for critical mutations from UI.

**Acceptance checks**
- Critical mutations fail when called directly from unauthorized clients.
- Function logs include caller role/shop validation.

---

## Phase 2 — Finish Mandatory Core Business Flows

### 4) Employee POS billing end-to-end
**Actions**
- Validate flow: customer mandatory → cart → payment selection → order creation → `confirmOrder` → inventory deduction → receipt.
- Ensure confirmed sales appear in daily sales summary and reports.

**Acceptance checks**
- Confirmed order is immutable.
- Inventory reduced atomically and never negative.
- Sales summary reflects locked orders for selected day.

### 5) Expense management compliance
**Actions**
- Admin/Super Admin only create/update expenses via callable functions.
- Enforce: amount > 0, no future date (if required), shop scoping, audit entries.

**Acceptance checks**
- Employee cannot create/update expense.
- Every expense change has actor-linked audit log.

### 6) Reports & analytics implementation
**Actions**
- Implement mandatory report surfaces from requirements:
  - Daily/monthly sales
  - Top-selling products
  - Inventory movement summary
  - Expense totals
- Enforce role visibility (Employee own scope, Admin own shop, Super Admin cross-shop).

**Acceptance checks**
- Reports are queryable per role without cross-shop leakage.
- Report totals reconcile with orders/expenses collections.

---

## Phase 3 — Governance & Admin Completion

### 7) Super Admin controls
**Actions**
- Implement global admin management and shop lifecycle operations.
- Add cross-shop monitoring dashboards and governance actions.

### 8) Settings & configuration module
**Actions**
- Implement settings collection with controlled writes and read scopes.
- Protect defaults and critical toggles from unauthorized edits.

### 9) Employee management hardening
**Actions**
- Finalize account lifecycle actions (active/inactive/suspended).
- Ensure role immutability and strict shop assignment.

---

## Phase 4 — Production Hardening & Release

### 10) Firestore rule verification matrix
Build a role × collection × operation matrix test and verify all allow/deny outcomes.

### 11) Cloud Function integration tests
Create emulator tests for:
- `confirmOrder`
- expense functions
- account status change functions
- audit callables

### 12) Data migration + seed scripts
- Normalize legacy enum values.
- Seed deterministic test data for 2+ shops and all 4 roles.

### 13) UAT checklist
- Execute business scenario scripts from requirements with pass/fail logs.

---

## Recommended Immediate Sprint (next 5–7 days)
1. Canonical enum contract + migration script.
2. Auth audit callable integration in login/logout/reset flows.
3. Expense writes routed only via Cloud Functions.
4. Rule/function regression test matrix for roles and shop isolation.

Deliver these first; they unlock stable development for reports, super admin controls, and release hardening.
