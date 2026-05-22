````md
# 🧾 POS System

A modern, secure, and scalable Point of Sale (POS) system built using Flutter and Firebase for retail stores, wholesale businesses, supermarkets, and inventory-based shops.

The system replaces traditional manual billing and inventory handling with a fully digital workflow designed for:

- Fast POS billing
- Real-time inventory management
- Role-based access control
- Customer and order tracking
- Expense management
- Secure audit logging
- Multi-shop ready architecture

The application supports both:

- Weight-based products
- Unit-based products

---

# 🚀 Features

## 🔐 Authentication & Security

- Firebase Authentication
- Role-based login system
- Session management
- Account activation / suspension
- Password reset flow
- Audit logging for authentication events

### Supported Roles

| Role | Access |
|------|--------|
| Super Admin | Global system control |
| Admin | Shop-level management |
| Employee | POS billing only |
| Viewer | Read-only analytics |

---

# 🛒 POS Billing System

Employee-focused billing workflow with a fast checkout experience.

### Features

- Product search & selection
- Weight-based and quantity-based billing
- Live price calculation
- Mandatory customer capture
- Multiple payment methods
- Receipt generation
- Real-time stock deduction

### Supported Payments

- Cash
- UPI / Online Payment
- Card

---

# 📦 Inventory & Product Management

Admins can manage products and inventory securely.

### Product Features

- Add / edit / disable products
- Product categories
- Price management
- Measurement type enforcement
- Low-stock alerts

### Inventory Features

- Automatic stock updates
- Inventory logs
- Real-time stock validation
- Prevent negative stock

---

# 👥 Customer Management

- Mandatory customer details for every order
- Customer order history linkage
- Repeat customer support
- Permanent customer records

---

# 📊 Reports & Analytics

Read-only reporting system for business insights.

### Available Reports

- Daily / Weekly / Monthly sales
- Product-wise sales
- Employee performance
- Expense reports
- Revenue tracking

---

# 💰 Expense Management

Track operational expenses with audit-safe workflows.

### Features

- Add & update expenses
- Expense history
- Validation rules
- Role-based restrictions

---

# 📜 Audit Logs & Compliance

The system maintains append-only audit logs for:

- Login/logout events
- Failed login attempts
- Product price changes
- Inventory updates
- Expense modifications
- Order cancellations
- Permission changes

Audit logs are immutable and cannot be modified or deleted.

---

# 🏗️ Tech Stack

## Frontend

- Flutter
- Dart
- Provider State Management
- Responsive UI for mobile & tablet POS usage

## Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Storage
- Firebase Hosting

---

# 🔥 Firebase Architecture

The project follows a strict serverless architecture:

| Layer | Technology |
|------|-------------|
| Client | Flutter |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Backend Enforcement | Cloud Functions |
| File Storage | Firebase Storage |
| Hosting | Firebase Hosting |

All critical business logic is enforced at backend level using Cloud Functions and Firestore Security Rules.

---

# 🔒 Security Model

The system follows a strict:

- Deny-by-default policy
- Role-based access control (RBAC)
- Shop-level data isolation
- Immutable transactional records

### Security Guarantees

- Orders are immutable after payment
- Inventory updates are atomic
- Audit logs are append-only
- Unauthorized access is blocked
- Cross-shop access restricted

---

# 🧱 Core Modules

- Authentication & Account Lifecycle
- Role-Based Access Control (RBAC)
- POS Billing
- Customer Management
- Product Management
- Inventory Management
- Orders & Payments
- Expense Management
- Reports & Analytics
- Employee Management
- Audit Logs
- Settings & Configuration
- Multi-Shop Architecture Support

---

# 📂 Project Structure

```bash
lib/
│
├── core/
├── features/
│   ├── auth/
│   ├── pos/
│   ├── products/
│   ├── inventory/
│   ├── customers/
│   ├── orders/
│   ├── expenses/
│   ├── reports/
│   └── settings/
│
├── services/
├── models/
├── widgets/
└── main.dart
```

---

# 🗄️ Firestore Collections

```bash
users/
shops/
products/
categories/
orders/
order_items/
customers/
inventory_logs/
expenses/
audit_logs/
settings/
```

---

# ⚙️ Getting Started

## Prerequisites

Before running the project, ensure you have:

- Flutter SDK installed
- Firebase project configured
- Android Studio / VS Code
- Dart SDK
- Firebase CLI

---

# 🛠️ Installation

## 1. Clone Repository

```bash
git clone https://github.com/your-username/pos-system.git
cd pos-system
```

## 2. Install Dependencies

```bash
flutter pub get
```

## 3. Configure Firebase

Run:

```bash
flutterfire configure
```

Add generated Firebase config files:

- `google-services.json`
- `GoogleService-Info.plist`

---

# 🔑 Environment Configuration

Required Firebase services:

- Authentication
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- Firebase Hosting

---

# ▶️ Run Application

```bash
flutter run
```

---

# 🧪 Build APK

```bash
flutter build apk --release
```

---

# 🚀 Deployment

## Android Release

```bash
flutter build apk --release
```

## Web Build

```bash
flutter build web
```

## Firebase Hosting

```bash
firebase deploy
```

---

# 📱 App Screenshots

| Login Screen | POS Billing | Admin Dashboard |
|--------------|-------------|-----------------|
| ![](screenshots/login.png) | ![](screenshots/pos.png) | ![](screenshots/dashboard.png) |

---

# 🏛️ System Architecture

```text
Flutter App
     ↓
Firebase Authentication
     ↓
Cloud Firestore
     ↓
Cloud Functions
     ↓
Firebase Storage
```

---

# 🌐 Future Scalability

The architecture is prepared for future upgrades including:

- Multi-shop support
- Online ordering
- Customer mobile app
- Advanced analytics
- Offline synchronization
- GST & invoice integrations
- Delivery management
- Barcode scanner integrations
- Thermal printer support

---

# 📄 Documentation

The complete project requirements and architecture are defined in the documents inside the `docs/` folder.

## Source of Truth Documents

- Software Requirements Specification (SRS)
- Requirement in Detail
- Technical Requirements in Detail
- Prompt-Based Model for AI-Assisted Development

These documents are authoritative and must not be overridden during development.

---

# 📌 Project Status

✅ Core Modules Completed  
✅ Firebase Backend Structured  
✅ Role-Based Access Control Implemented  
✅ POS Billing Workflow Completed  
🚧 Final Testing & Optimization Ongoing

---

# 🤝 Development Guidelines

- Follow strict RBAC enforcement
- Never bypass backend validations
- Maintain immutable transactional history
- Use Cloud Functions for critical operations
- Preserve audit logs and inventory integrity
- Follow clean architecture principles

---

# 📃 License

This project is private and intended for internal/business use.

---

# 👨‍💻 Developed With

- Flutter
- Firebase
- Cloud Firestore
- Firebase Functions
- Dart

Built for scalable and secure retail business operations.
````
