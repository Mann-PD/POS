# POS System Cloud Functions

Firebase Cloud Functions for the Fruit Retail & Wholesale POS System.

## Architecture

All critical business logic and mutations are enforced server-side through Cloud Functions. The frontend (Flutter) cannot bypass these rules.

## Functions

### Order Functions

- **confirmOrder** (Callable)
  - Confirms an order and deducts inventory atomically
  - Validates employee role, stock availability, customer details
  - Creates order, order items, and inventory logs
  - Only Employees can create orders

- **cancelOrder** (Callable)
  - Cancels an order (Admin/Super Admin only)
  - Logs cancellation for audit
  - Orders cannot be deleted

### Product Triggers

- **onPriceChange** (Firestore Trigger)
  - Logs all price changes for audit
  - Triggered when product price is updated

### Expense Triggers

- **onExpenseCreate** (Firestore Trigger)
  - Logs expense creation

- **onExpenseUpdate** (Firestore Trigger)
  - Logs expense updates

- **onExpenseDelete** (Firestore Trigger)
  - Logs expense deletion (Super Admin only per security rules)

### Authentication Functions

- **logLoginSuccess** (Callable)
  - Logs successful login

- **logLoginFailure** (Callable)
  - Logs failed login attempts

- **logLogout** (Callable)
  - Logs user logout

- **onUserStatusChange** (Firestore Trigger)
  - Logs user account status changes

## Business Rules Enforced

1. **Role Validation**: Every function validates user role and shopId
2. **Atomic Operations**: Order confirmation uses Firestore transactions
3. **Inventory Integrity**: Stock cannot go below zero
4. **Audit Logging**: All critical actions are logged
5. **Data Immutability**: Orders, customers, audit logs are immutable
6. **Customer Mandatory**: Orders require customer details

## Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Run emulator
npm run serve

# Deploy
npm run deploy
```

## Type Safety

All functions use TypeScript with strict type checking. Types are defined in `src/types/index.ts` based on the Firestore schemas.

## Security

- All functions require authentication (except where explicitly public)
- Role and shopId are validated in every function
- Never trust frontend data - all inputs are validated
- Firestore Security Rules provide additional protection
