Requirement in Detail

Fruit Retail & Wholesale POS System

1\. System Scope & Overview

1.1 Purpose of the System

The Fruit Retail & Wholesale POS System is a complete digital Point of
Sale solution designed to manage and control all operational activities
of a fruit retail shop or wholesale fruit business.

The system replaces traditional manual billing, paper-based records, and
unstructured processes with a secure, reliable, and structured digital
platform that improves:

- Billing accuracy

- Transaction speed

- Inventory control

- Business transparency

- Accountability across staff

The system is designed to support day-to-day sales operations as well as
management-level monitoring and control, while ensuring strict access
control and data security.

Mandatory System Requirements

- The system SHALL enforce digital billing for every sales transaction.

- The system MUST NOT allow order creation or order completion without
  mandatory customer details.

- The system SHALL support both weight-based and unit-based sales
  accurately.

- The system MUST store all transactional and operational data securely.

- The system SHALL provide real-time visibility of stock, sales, and
  financial data.

- The system SHALL maintain full auditability of critical actions.

1.2 Business Scope

The system is designed to support both retail and wholesale business
models within the same application.

Supported Sales Models

- Weight-based selling

  - Kilograms (kg)

  - Grams (gm)

- Unit-based selling

  - Pieces

  - Boxes / crates

Supported Customer Types

- Walk-in retail customers

- Bulk buyers

- Repeat wholesale customers

Target Business Types

- Small fruit shops

- Medium-sized fruit retail stores

- Wholesale fruit traders and distributors

1.3 Shop & Multi-Shop Structure

The system operates as a single-shop POS system in the current phase.

However, the system is architected to support multi-shop / multi-branch
expansion in future versions without major redesign.

Each shop is treated as an independent business unit with its own
isolated data.

Shop-Level Data Includes

- Products & categories

- Inventory stock

- Orders & payments

- Customers

- Employees

- Expenses

- Reports & analytics

1.3.1 Data Ownership & Isolation Policy

- Each shop SHALL OWN its own operational data.

- Data isolation MUST be enforced at the database level.

- One shop MUST NOT view or modify another shop's data.

- Cross-shop access is ONLY permitted for Super Admin users.

- All database queries MUST be filtered using Shop ID.

- Reports and dashboards MUST display data only for the logged-in user's
  shop.

1.4 In-Scope Functional Areas

The following functional areas are fully included within the system
scope:

- Role-based authentication and authorization

- Employee POS billing workflow

- Mandatory customer information capture

- Product and inventory management

- Expense tracking and financial control

- Sales reports and business analytics

- Audit logging for critical system actions

- Role-based UI and backend access enforcement

1.5 Out-of-Scope Areas

The following features are explicitly excluded from the current system
scope:

- Online customer ordering

- Home delivery or logistics management

- Customer-facing mobile applications

- Integration with external accounting software

- Third-party marketplace integrations

These may be considered in future phases.

2\. User Roles Definition

The system follows a strict role-based operating model.

- Each user is assigned exactly one role.

- All permissions are derived only from that role.

- No user can override role-based restrictions.

2.1 Super Admin

Role Purpose

The Super Admin represents the system owner or platform administrator.

This role is responsible for overall system governance and high-level
configuration.

Authority Level

- Highest authority in the system

- System-wide visibility

- Cross-shop access (when multi-shop is enabled)

Responsibilities

- Create, manage, and deactivate Admin users

- Define and manage role permissions

- Configure global system settings

- Monitor system-wide activity and audit logs

- Control multi-shop behavior and access

Operational Restrictions

- Super Admin DOES NOT perform daily POS billing.

- Super Admin DOES NOT participate in shop-level sales operations.

2.2 Admin (Shop Owner / Manager)

Role Purpose

The Admin represents the owner or manager of a specific shop.

This role focuses on business management, control, and monitoring.

Authority Level

- Full authority within a single shop

- No access to global system configuration

Responsibilities

- Manage products, categories, and pricing

- Control and monitor inventory levels

- Manage employees and their access

- View all orders, expenses, and reports

- Configure shop-level settings

Admin POS Usage Restriction

- Admin users SHALL NOT perform POS billing operations.

- This separation ensures:

  - Clear accountability

  - Accurate employee performance tracking

  - Reduced fraud risk

  - Clean audit trails

Admins may view orders but MUST NOT create or modify active sales
orders.

2.3 Employee (POS User / Cashier)

Role Purpose

Employees handle daily sales operations at the billing counter.

Authority Level

- Limited access strictly focused on POS operations

Responsibilities

- Create customer orders

- Select products and quantities

- Capture mandatory customer details

- Collect payments

- Generate receipts

- View own daily sales summary

Operational Boundaries

Employees MUST NOT:

- Edit product prices

- Manage inventory manually

- View shop-level reports

- Access expenses

- Manage employees

- View other employees' sales data

2.4 Viewer / Accountant (Optional Role)

Role Purpose

This role provides read-only access for accountants, auditors, or
business reviewers.

Authority Level

- Read-only access

Responsibilities

- View sales reports

- View order history

- View expense summaries

No data modification is allowed.

3\. Role-Based Access Control (RBAC) Model

3.1 Access Control Philosophy

The system follows a strict Role-Based Access Control (RBAC) model.

- Every system action is validated against the user's role

- Any action not explicitly allowed is automatically denied

- Permissions apply consistently across all screens and modules

3.2 Access Types Defined

- Read -- View data only

- Write -- Create or update data

- Delete -- Remove or deactivate data (where permitted)

3.3 Permission Enforcement Layers

Permissions are enforced at two mandatory levels:

UI-Level Enforcement

- Restricted screens are hidden

- Unauthorized buttons and actions are disabled

Backend-Level Enforcement

- Every API/database request validates user role

- Unauthorized requests are rejected immediately

UI restriction alone SHALL NOT be considered secure.

4\. Global Role-Based Access Matrix

  ----------------------------------------------
  Module           Employee   Admin    Super
                                       Admin
  ---------------- ---------- -------- ---------
  Authentication   Read       Read     Read

  POS Billing      Write      Read     Read

  Products         Read       Write    Write

  Inventory        Read       Write    Write

  Orders           Write      Read     Write
                   (Own)               

  Customers        Write      Read     Write

  Payments         Write      Read     Read

  Expenses         No Access  Write    Write

  Reports          Own Only   Read     Read

  Employee         No Access  Write    Write
  Management                           

  Admin Management No Access  No       Write
                              Access   

  System Settings  No Access  No       Write
                              Access   
  ----------------------------------------------

5\. Module-Level Access Matrices

5.1 Product Module

  ---------------------------------------
  Action     Employee   Admin   Super
                                Admin
  ---------- ---------- ------- ---------
  View       Read       Read    Read
  products                      

  Add        ❌         Write   Write
  product                       

  Edit       ❌         Write   Write
  product                       

  Change     ❌         Write   Write
  price                         

  Disable    ❌         Write   Write
  product                       

  Delete     ❌         ❌      Write
  product                       
  ---------------------------------------

5.2 Order Module

  -----------------------------------------------
  Action             Employee   Admin   Super
                                        Admin
  ------------------ ---------- ------- ---------
  Create order       Write      ❌      ❌

  Edit order (before Write      ❌      ❌
  payment)                              

  Cancel order       ❌         Write   Write

  View orders        Own Only   Read    Read

  Delete order       ❌         ❌      ❌
  -----------------------------------------------

5.3 Customer Module (Mandatory)

  ----------------------------------------
  Action      Employee   Admin   Super
                                 Admin
  ----------- ---------- ------- ---------
  Add         Write      Write   Write
  customer                       

  View        ❌         Read    Read
  history                        

  Edit        ❌         Write   Write
  details                        

  Delete      ❌         ❌      ❌
  customer                       
  ----------------------------------------

Mandatory Customer Rule

- Orders MUST NOT be completed without:

  - Customer Name

  - Mobile Number

- Customer deletion is strictly prohibited to preserve billing history.

5.4 Expense Module

  ---------------------------------------
  Action     Employee   Admin   Super
                                Admin
  ---------- ---------- ------- ---------
  Add        ❌         Write   Write
  expense                       

  Edit       ❌         Write   Write
  expense                       

  View       ❌         Read    Read
  expenses                      

  Delete     ❌         ❌      Write
  expense                       
  ---------------------------------------

6\. Audit & Compliance Requirements

6.1 Audit Logging

The system SHALL log all critical actions, including:

- User login and logout

- Order cancellation

- Price changes

- Inventory updates

- Expense modifications

- Permission changes

Each log entry MUST include:

- User ID

- User role

- Action performed

- Timestamp

- Affected record ID

Audit logs SHALL NOT be editable by any role.

7\. Authentication Module Overview

7.1 Purpose of the Authentication Module

The Authentication Module is responsible for secure system entry, role
identification, and controlled user access within the Fruit Retail &
Wholesale POS System.

This module ensures that:

- Only authorized users can access the system

- Each user is authenticated and assigned a single, fixed role

- Users can only access screens and features permitted by their role

- User accounts follow a controlled lifecycle (creation, activation,
  suspension, deactivation)

- All authentication activity is secure, traceable, and auditable

The authentication process is common and consistent for:

- Super Admin

- Admin

- Employee

- Viewer / Accountant (optional role)

7.2 Core Responsibilities of the Authentication Module

The Authentication Module SHALL control:

- Secure login and logout

- Role detection and validation

- Role-based dashboard redirection

- User account creation and activation workflow

- Password security and recovery

- Session lifecycle and timeout handling

- Authentication-related audit logging

This module acts as the security gateway to the entire system.

8\. User Login Requirements

8.1 Login Purpose

The Login process allows authorized users to securely enter the system
and ensures automatic redirection to the correct role-specific
interface.

The system MUST NOT allow access to any internal screen without
successful authentication.

8.2 Who Can Access the Login Screen

  -------------------------
  User Type     Access
  ------------- -----------
  Super Admin   Allowed

  Admin         Allowed

  Employee      Allowed

  Viewer /      Allowed
  Accountant    

  Public /      ❌ Not
  Guest         Allowed
  -------------------------

8.3 Login Inputs

The Login Screen SHALL collect the following mandatory inputs:

- Registered Email Address or Registered Phone Number

- Password

Rules:

- All fields are mandatory

- Password input must be masked

- Inputs are validated before submission

8.4 Login Flow

1.  User enters login credentials

2.  System validates email/phone and password

3.  System identifies assigned role

4.  System checks account status

5.  System creates a secure session

6.  User is redirected to the correct dashboard

If any step fails, login is rejected with a clear message.

8.5 Role-Based Redirection Rules

After successful login, users SHALL be redirected automatically as
follows:

- Employee → POS Home / Billing Screen

- Admin → Admin Dashboard (Shop-Specific)

- Super Admin → System Dashboard (Global)

- Viewer / Accountant → Reports & Analytics Dashboard

Users CANNOT manually switch dashboards or access other role panels.

8.6 Login Validations

The system MUST validate:

- Email/phone is registered

- Password is correct

- Account status is Active

- Role is assigned

- Shop is assigned (for Admin & Employee roles)

Failure of any validation SHALL block login.

8.7 Login Security Rules

- Multiple failed login attempts MAY temporarily lock the account

- All login attempts SHALL be logged

- Error messages MUST NOT expose sensitive system information

9\. User Registration & Account Creation

9.1 Registration Policy

The system follows a strictly controlled registration model.

Rules:

- Public self-registration is NOT ALLOWED

- Employees can only be created by Admin or Super Admin

- Admins can only be created by Super Admin

- Super Admin accounts are created during system setup only

This prevents unauthorized access and misuse.

9.2 Mandatory User Data

When creating a user account, the following data is required:

- Full Name

- Email Address

- Phone Number

- Role Assignment

- Shop Assignment (except Super Admin)

- Initial Account Status (Active / Inactive)

9.3 User Creation Flow

1.  Authorized user opens User Management screen

2.  User details are entered

3.  Role is selected

4.  Shop is assigned

5.  Initial account status is set

6.  Account is created securely

9.4 Registration Validations

- Email must be unique

- Role must be selected

- Shop must be assigned

- Required fields cannot be empty

9.5 Registration Restrictions

  ------------------------------------------
  Action        Employee   Admin   Super
                                   Admin
  ------------- ---------- ------- ---------
  Create        ❌         ✅      ✅
  Employee                         

  Create Admin  ❌         ❌      ✅

  Create Super  ❌         ❌      ❌
  Admin                            
  ------------------------------------------

10\. Account Status Management

10.1 Account States

Each user account SHALL have one of the following states:

- Active -- Login allowed

- Inactive -- Login blocked

- Suspended -- Temporarily blocked due to policy or security reasons

10.2 Activation Rules

- New accounts may be Active or Inactive

- Only Admin or Super Admin can activate accounts

- Status changes apply immediately

10.3 Deactivation Rules

- Deactivated users cannot log in

- User-generated data remains unchanged

- User history is preserved for audit purposes

11\. Password Management

11.1 Password Rules

- Passwords must meet minimum strength requirements

- Passwords are stored securely (hashed/encrypted)

- Passwords are never visible to Admins or other users

11.2 Forgot Password Flow

1.  User selects "Forgot Password"

2.  Enters registered email

3.  System sends reset instructions

4.  User sets a new password

11.3 Password Reset Validations

- Email must be registered

- Reset link must be valid and time-bound

- New password must meet security rules

12\. Session Management

12.1 Session Creation

- A session is created after successful login

- Session is bound to:

  - User ID

  - Role

  - Shop ID

12.2 Session Timeout

- Session expires after configured inactivity

- User is automatically logged out

- Sensitive session data is cleared

12.3 Concurrent Login Rules

- Same user should not log in from multiple devices simultaneously

- This rule is configurable by Super Admin

12.4 Logout Rules

- User can log out manually

- Session data is destroyed immediately

- Logout is logged for audit

13\. Access Control Enforcement

13.1 Permission Validation

- Every screen and action validates role permissions

- Unauthorized actions are blocked automatically

- Permissions are enforced at:

  - UI level

  - Backend level

13.2 Unauthorized Access Handling

- Direct URL or deep-link access is blocked

- User is redirected to the permitted dashboard

- Repeated violations may result in suspension

14\. Audit & Logging (Authentication Module)

14.1 Logged Activities

The system SHALL log:

- Successful logins

- Failed login attempts

- Account creation

- Account activation/deactivation

- Password reset requests

- Logout events

14.2 Audit Purpose

Authentication logs are used for:

- Security monitoring

- Compliance and audits

- Issue investigation

- User activity tracking

Audit logs CANNOT be edited or deleted by any role.

15\. Role-Based Access Visibility (Authentication Level)

This section defines what each role can see immediately after login,
before any business operation begins.

15.1 Super Admin -- Authentication-Level Access

- Login Access: Allowed

- Landing Screen: System Dashboard

Visible Modules:

- System Overview

- Admin Management

- Global Settings

- Audit Logs

- Reports (Cross-Shop)

Restricted:

- POS Billing

- Shop-Level Sales Operations

15.2 Admin -- Authentication-Level Access

- Login Access: Allowed

- Landing Screen: Admin Dashboard

Visible Modules:

- Products & Inventory

- Orders (Read-only)

- Employees

- Expenses

- Reports

- Shop Settings

Restricted:

- POS Billing

- System-Level Configuration

- Admin Creation

15.3 Employee -- Authentication-Level Access

- Login Access: Allowed

- Landing Screen: POS Home / Billing Screen

Visible Modules:

- Product Selection

- Cart & Billing

- Customer Entry

- Payment Processing

- Receipt Generation

- Own Sales Summary

Restricted:

- Admin Dashboard

- Inventory Management

- Expenses

- Reports (except own)

- User Management

- Settings

15.4 Viewer / Accountant -- Authentication-Level Access

- Login Access: Allowed

- Landing Screen: Reports Dashboard

Visible Modules:

- Sales Reports

- Order History

- Expense Summaries

Restricted:

- POS Billing

- Product & Inventory Management

- User Management

- Settings

15\. Employee (POS User) Module -- Overview

15.1 Module Purpose

The Employee (POS User) Module is designed to handle all day-to-day
sales and billing operations performed at the shop counter.

This module focuses on:

- Fast billing

- Minimal steps

- Touch-friendly usage

- Error prevention

- Strict permission control

Employees operate strictly within predefined POS boundaries and cannot
access management, configuration, or financial control features.

15.2 Who Can Access the Employee Module

  -----------------------
  Role           Access
  -------------- --------
  Employee (POS  ✅ Yes
  User)          

  Admin          ❌ No

  Super Admin    ❌ No

  Public / Guest ❌ No
  -----------------------

Access is enforced at authentication, UI, and backend levels.

15.3 Employee Module Restrictions (Global)

Employees MUST NOT:

- Change product prices

- Modify inventory manually

- Add, edit, or delete products

- Apply discounts

- Access expenses or profit reports

- Manage users or roles

- Access admin or system dashboards

Any attempt to bypass restrictions SHALL be blocked and logged.

16\. POS Home / Product Selection Screen

16.1 Purpose

This is the primary working screen for employees.\
All billing activities start and reset from this screen.

16.2 Screen Description

The screen displays:

- Product categories (e.g., Fruits, Boxes, Wholesale)

- Product search bar

- Barcode / QR scan option

- Product grid (touch-optimized)

- Floating cart indicator with item count

Designed for tablet, mobile, and POS terminals.

16.3 Available Actions

- Browse products by category

- Search products by name

- Scan product barcode

- Select product to add to cart

- View current cart count

16.4 Permission Matrix

  --------------------------
  Action          Employee
  --------------- ----------
  View products   ✅

  Search / filter ✅
  products        

  Scan barcode    ✅

  Edit product    ❌

  Change price    ❌
  --------------------------

16.5 Business Rules

- Only active products are displayed

- Out-of-stock products are disabled or marked unavailable

- Product prices are auto-fetched and read-only

16.6 Validations

- Product must exist

- Product must be active

- Available stock must be greater than zero

17\. Add to Cart Screen (Quantity / Weight Selection)

17.1 Purpose

Allows employees to specify quantity or weight before adding a product
to the cart.

17.2 Screen Description

Displays:

- Product name and image

- Measurement type (kg / gm / piece / box)

- Price per unit or per kg

- Quantity or weight input field

- Live price calculation

17.3 Permission Matrix

  ----------------------------
  Action            Employee
  ----------------- ----------
  Enter quantity /  ✅
  weight            

  Add item to cart  ✅

  Change            ❌
  measurement type  
  ----------------------------

17.4 Business Rules

- Weight-based products allow decimal values

- Unit-based products allow whole numbers only

- Quantity/weight cannot exceed available stock

17.5 Validations

- Quantity or weight must be greater than zero

- Input type must match product measurement type

18\. Cart Summary Screen

18.1 Purpose

Allows employees to review and adjust cart items before checkout.

18.2 Screen Description

Displays:

- List of cart items

- Quantity adjustment controls

- Per-item total

- Cart subtotal

- "Proceed to Checkout" button

18.3 Permission Matrix

  ---------------------
  Action     Employee
  ---------- ----------
  View cart  ✅

  Edit       ✅
  quantity   

  Remove     ✅
  item       

  Apply      ❌
  discount   
  ---------------------

18.4 Business Rules

- Cart must contain at least one item

- Total price recalculates in real time

18.5 Validations

- Cart cannot be empty

- Quantity must remain valid and within stock limits

19\. Customer Details Screen (MANDATORY)

19.1 Purpose

Collects mandatory customer information required to complete an order.

19.2 Input Fields

- Customer Name (mandatory)

- Mobile Number (mandatory)

19.3 Permission Matrix

  -------------------------
  Action         Employee
  -------------- ----------
  Add customer   ✅
  details        

  Skip customer  ❌
  details        
  -------------------------

19.4 Business Rules

- Order CANNOT proceed without customer details

- Customer data is permanently linked to the order

19.5 Validations

- Customer name cannot be empty

- Mobile number must be valid

20\. Payment Selection Screen

20.1 Purpose

Allows employees to select the payment method and complete the order.

20.2 Supported Payment Methods

- Cash

- UPI / Online Payment

- Card

20.3 Permission Matrix

  --------------------------
  Action          Employee
  --------------- ----------
  Select payment  ✅
  method          

  Confirm payment ✅

  Partial / split ❌
  payment         
  --------------------------

20.4 Business Rules

- Payment method selection is mandatory

- Order cannot be completed without payment confirmation

20.5 Validations

- Payment method must be selected

21\. Order Success & Receipt Screen

21.1 Purpose

Confirms successful order placement and provides receipt details.

21.2 Displayed Information

- Order ID

- Date & time

- Product list

- Total amount

- Payment method

- Customer name and mobile number

21.3 Permission Matrix

  ------------------------
  Action        Employee
  ------------- ----------
  View receipt  ✅

  Print / share ✅
  receipt       

  Edit order    ❌
  ------------------------

21.4 Business Rules

- Stock deduction occurs only after order confirmation

- Completed orders become immutable

22\. Daily Sales Summary Screen (Employee)

22.1 Purpose

Allows employees to view their own daily sales performance.

22.2 Displayed Data

- Number of orders handled

- Total sales amount

- Date-wise sales summary

22.3 Permission Matrix

  -----------------------------
  Action             Employee
  ------------------ ----------
  View own sales     ✅

  View other         ❌
  employees' sales   
  -----------------------------

22.4 Business Rules

- Employees can view only their own data

- Data is read-only

23\. Global Employee Module Rules

- Employees CANNOT modify prices

- Employees CANNOT bypass customer details

- Employees CANNOT access admin modules

- Employees CANNOT edit completed orders

- All employee actions are logged for audit purposes

24\. Admin Module -- Overview

24.1 Purpose

The Admin Module is designed for shop owners and shop managers to
control, configure, monitor, and analyze all business operations of a
single shop.

Unlike the Employee (POS User) module, this module:

- Focuses on decision-making and control

- Manages products, inventory, staff, and expenses

- Provides reports and business insights

- Does NOT support direct POS billing

24.2 Who Can Access the Admin Module

  -----------------------------
  Role                 Access
  -------------------- --------
  Admin (Shop Owner /  ✅ Yes
  Manager)             

  Super Admin          ✅ Yes

  Employee             ❌ No

  Public / Guest       ❌ No
  -----------------------------

Access is enforced at authentication, UI, and backend levels.

24.3 Admin Module Responsibilities

The Admin Module SHALL allow authorized users to:

- Manage products and pricing

- Control and adjust inventory stock

- Create and manage POS employees

- Track and manage expenses

- View and analyze sales performance

- Audit completed and cancelled orders

- Configure shop-level settings

25\. Admin Dashboard

25.1 Purpose

The Admin Dashboard provides a real-time summary of the shop's business
health and operational performance.

25.2 Displayed Information

The dashboard SHALL display:

- Today's total sales amount

- Number of orders completed

- Total revenue

- Low-stock alerts

- Number of active employees

- Recent orders summary

25.3 Permission Matrix

  ---------------------------------
  Action          Admin   Super
                          Admin
  --------------- ------- ---------
  View dashboard  Read    Read

  Modify          ❌      ❌
  dashboard data          
  ---------------------------------

25.4 Business Rules

- Dashboard data is read-only

- Data refreshes automatically

- Historical data CANNOT be modified

26\. Product Management Module

26.1 Purpose

Allows Admin and Super Admin to manage all sellable products within the
shop.

26.2 Permission Matrix

  ----------------------------
  Action     Admin   Super
                     Admin
  ---------- ------- ---------
  View       Read    Read
  products           

  Add        Write   Write
  product            

  Edit       Write   Write
  product            

  Change     Write   Write
  price              

  Disable    Write   Write
  product            

  Delete     ❌      Write
  product            
  ----------------------------

26.3 Business Rules

- Product price MUST be greater than zero

- Measurement type CANNOT be changed after first sale

- Disabled products CANNOT be sold

- Deleted products remain visible in historical orders

26.4 Validations

- Product name MUST be unique per shop

- Stock quantity CANNOT be negative

27\. Inventory Management Module

27.1 Purpose

Tracks, updates, and controls real-time stock levels for all products.

27.2 Permission Matrix

  ------------------------------
  Action       Admin   Super
                       Admin
  ------------ ------- ---------
  View stock   Read    Read

  Update stock Write   Write

  Set          Write   Write
  low-stock            
  alert                
  ------------------------------

27.3 Business Rules

- Stock automatically reduces after each completed sale

- Stock CANNOT go below zero

- Low-stock alerts trigger automatically when threshold is reached

28\. Employee Management Module

28.1 Purpose

Manages POS employees, their access, and operational status.

28.2 Permission Matrix

  -------------------------------
  Action        Admin   Super
                        Admin
  ------------- ------- ---------
  View          Read    Read
  employees             

  Add employee  Write   Write

  Edit employee Write   Write

  Activate /    Write   Write
  Deactivate            

  Delete        ❌      Write
  employee              
  -------------------------------

28.3 Business Rules

- Deactivated employees CANNOT log in

- Employee sales and order history MUST remain intact

- Deletion does NOT remove historical data

29\. Expense Management Module

29.1 Purpose

Tracks daily and operational expenses of the shop.

29.2 Permission Matrix

  ----------------------------
  Action     Admin   Super
                     Admin
  ---------- ------- ---------
  Add        Write   Write
  expense            

  Edit       Write   Write
  expense            

  View       Read    Read
  expenses           

  Delete     ❌      Write
  expense            
  ----------------------------

29.3 Business Rules

- Expense amount MUST be greater than zero

- Future-dated expenses ARE NOT allowed

- Expense deletion is restricted to Super Admin only

30\. Order History & Audit Module

30.1 Purpose

Provides complete visibility and auditability of all completed and
cancelled orders.

30.2 Permission Matrix

  ---------------------------
  Action    Admin   Super
                    Admin
  --------- ------- ---------
  View      Read    Read
  orders            

  Cancel    Write   Write
  order             

  Delete    ❌      ❌
  order             
  ---------------------------

30.3 Business Rules

- Orders CANNOT be deleted

- Order cancellation MUST be logged

- Cancelled orders remain visible for audit and reporting

31\. Reports & Analytics Module

31.1 Purpose

Provides business intelligence and insights for decision-making.

31.2 Permission Matrix

  ----------------------------
  Action     Admin   Super
                     Admin
  ---------- ------- ---------
  View       Read    Read
  reports            

  Export     Write   Write
  reports            
  ----------------------------

31.3 Report Types

- Sales reports (daily, weekly, monthly)

- Product-wise sales reports

- Employee-wise performance reports

- Expense reports

All reports are read-only.

32\. Settings & Configuration Module

32.1 Purpose

Allows configuration of shop-level operational rules.

32.2 Permission Matrix

  ----------------------------------------
  Action                 Admin   Super
                                 Admin
  ---------------------- ------- ---------
  Change tax rules       Write   Write

  Enable / disable       Write   Write
  payment methods                

  Configure POS behavior Write   Write

  System-level settings  ❌      Write
  ----------------------------------------

32.3 Business Rules

- Settings apply only to future orders

- Critical changes REQUIRE confirmation

- Settings changes are logged for audit

33\. Super Admin -- Additional Capabilities

33.1 Global System Control

The Super Admin has system-wide authority to:

- Create, manage, and deactivate Admin users

- Control multi-shop access and visibility

- Configure system-level policies

- Monitor global audit logs

33.2 Super Admin Restrictions

Super Admin MUST NOT:

- Perform POS billing

- Modify historical sales data

- Alter completed order records

34\. Global Admin & Super Admin Rules

- Admin access is limited to assigned shop

- Super Admin has cross-shop visibility

- All actions are logged for audit

- Role-based restrictions cannot be bypassed

34.1 Pricing Rules

- Product price MUST always be greater than zero

- Prices SHALL be defined and modified only by Admin or Super Admin

- Price changes APPLY ONLY to future orders

- Employees CANNOT override, edit, or negotiate prices

- Historical order prices MUST remain unchanged permanently

- All price changes SHALL be logged for audit

34.2 Inventory Rules

- Stock quantity MUST NOT be negative

- Stock SHALL reduce only after successful order confirmation

- Stock updates MUST reflect immediately across all POS screens

- Out-of-stock products CANNOT be billed

- Low-stock alerts SHALL trigger automatically at defined thresholds

- Manual inventory adjustments ARE RESTRICTED to Admin & Super Admin

34.3 Order Rules

- Every order MUST be linked to a customer

- Orders MUST contain at least one product

- Orders CANNOT be edited after payment confirmation

- Orders CANNOT be deleted under any circumstances

- Cancelled orders MUST retain full audit history

- Order IDs SHALL be unique and immutable

34.4 Customer Rules (MANDATORY)

- Customer name IS MANDATORY for every order

- Customer mobile number IS MANDATORY for every order

- Orders CANNOT proceed without valid customer details

- One customer MAY have multiple orders

- Customer data SHALL be permanently linked to order history

- Customer deletion IS STRICTLY PROHIBITED

34.5 Payment Rules

- Payment method selection IS MANDATORY

- Payment MUST be completed before order confirmation

- Partial or split payments ARE NOT allowed (unless enabled in future)

- Failed payments MUST NOT generate orders

- Payment details ARE IMMUTABLE after order completion

- Refunds (if supported) MUST follow admin-level workflows only

34.6 Role & Access Rules

- Users CAN ONLY access features assigned to their role

- Employees CANNOT access admin, reporting, or configuration modules

- Admins CANNOT access system-level settings

- Super Admin CONTROLS system-wide permissions

- Unauthorized access attempts SHALL be blocked immediately

- Repeated violations MAY result in suspension

34.7 Multi-Shop Rules

- Each shop's data MUST remain isolated

- Orders, inventory, employees, customers, and reports ARE shop-specific

- Cross-shop access IS RESTRICTED to Super Admin only

- Shop switching REQUIRES explicit authorization

- No shop CAN view or modify another shop's data

35\. System-Wide Validations

Validations ensure data accuracy, consistency, and integrity across all
modules.

35.1 Mandatory Field Validations

- Required fields MUST be filled before saving

- Missing mandatory data BLOCKS the action

- Clear and user-friendly error messages SHALL be displayed

35.2 Data Format Validations

- Mobile numbers MUST follow valid format

- Numeric fields MUST contain valid numbers

- Weight-based inputs ALLOW decimals

- Unit-based inputs ALLOW integers only

35.3 Permission Validations

- Every action MUST be validated against role permissions

- Restricted actions ARE BLOCKED immediately

- Users ARE redirected only to authorized screens

35.4 State-Based Validations

- Inactive or suspended users CANNOT log in

- Disabled products CANNOT be sold

- Completed orders CANNOT be modified

- Deactivated users LOSE access immediately

36\. Error Handling Rules

The system MUST handle errors gracefully without data loss.

36.1 User-Level Errors

Examples:

- Invalid login credentials

- Missing mandatory fields

- Invalid input formats

- Unauthorized actions

Rules:

- Errors SHALL be displayed clearly

- Messages MUST be simple and user-friendly

- System internals MUST NOT be exposed

36.2 System-Level Errors

Examples:

- Network connectivity issues

- Data fetch failures

- Unexpected system exceptions

Rules:

- Errors MUST NOT cause data corruption

- Retry or recovery options SHALL be provided

- System stability MUST be preserved

37\. Audit Logs & Activity Tracking

37.1 Purpose

Audit logs ensure:

- Transparency

- Accountability

- Security compliance

- Issue investigation

37.2 Logged Activities

The system SHALL log:

- User logins and logouts

- Failed login attempts

- User creation, activation, suspension, deactivation

- Product price changes

- Inventory updates

- Order cancellations

- Expense creation, edits, and deletions

37.3 Audit Log Rules

- Audit logs ARE READ-ONLY

- Logs CANNOT be deleted or modified

- Each log entry MUST include:

  - User ID

  - User Role

  - Action performed

  - Date & Time

  - Affected entity (where applicable)

38\. Data Integrity & Security Rules

- Duplicate records MUST be prevented

- Sensitive data SHALL be protected

- Role-based data isolation IS ENFORCED

- All critical actions ARE LOGGED

- Data consistency MUST be maintained across modules

- No module CAN bypass global rules

39\. Assumptions & Constraints

39.1 Assumptions

- Users have basic POS training

- Stable internet connectivity is available

- Devices meet minimum system requirements

39.2 Constraints

- System depends on cloud services

- Offline mode (if supported) is limited

- Performance depends on network quality

- Real-time features require active connectivity

40\. Final Notes

This Requirement in Detail document serves as the single source of truth
for the Fruit Retail & Wholesale POS System.

It ensures:

- No ambiguity in system behavior

- Clear understanding of roles and permissions

- Complete functional and non-functional coverage

- A strong foundation for development, testing, and deployment