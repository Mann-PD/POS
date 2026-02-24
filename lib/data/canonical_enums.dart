// Canonical enum definitions for Fruit POS System.
// Values MUST match backend Cloud Functions and Firestore rules exactly.
// Do NOT modify casing. No extra enum values allowed.

/// User role. Firestore: "SuperAdmin" | "Admin" | "Employee" | "Viewer"
enum Role {
  SuperAdmin,
  Admin,
  Employee,
  Viewer,
}

/// Account status. Firestore: "Active" | "Inactive" | "Suspended"
enum AccountStatus {
  Active,
  Inactive,
  Suspended,
}

/// Order status. Firestore: "pending" | "locked" | "cancelled"
enum OrderStatus {
  pending,
  locked,
  cancelled,
}

/// Payment status. Firestore: "Success" | "Pending" | "Failed"
enum PaymentStatus {
  Success,
  Pending,
  Failed,
}

// --- Role ---

extension RoleFirestore on Role {
  String get firestoreString => name;
}

extension RoleFirestoreParse on String {
  Role get toRole {
    for (final e in Role.values) {
      if (e.firestoreString == this) return e;
    }
    throw ArgumentError('Unknown Role value: "$this". Expected one of: ${Role.values.map((e) => e.firestoreString).join(", ")}');
  }
}

// --- AccountStatus ---

extension AccountStatusFirestore on AccountStatus {
  String get firestoreString => name;
}

extension AccountStatusFirestoreParse on String {
  AccountStatus get toAccountStatus {
    for (final e in AccountStatus.values) {
      if (e.firestoreString == this) return e;
    }
    throw ArgumentError('Unknown AccountStatus value: "$this". Expected one of: ${AccountStatus.values.map((e) => e.firestoreString).join(", ")}');
  }
}

// --- OrderStatus ---

extension OrderStatusFirestore on OrderStatus {
  String get firestoreString => name;
}

extension OrderStatusFirestoreParse on String {
  OrderStatus get toOrderStatus {
    for (final e in OrderStatus.values) {
      if (e.firestoreString == this) return e;
    }
    throw ArgumentError('Unknown OrderStatus value: "$this". Expected one of: ${OrderStatus.values.map((e) => e.firestoreString).join(", ")}');
  }
}

// --- PaymentStatus ---

extension PaymentStatusFirestore on PaymentStatus {
  String get firestoreString => name;
}

extension PaymentStatusFirestoreParse on String {
  PaymentStatus get toPaymentStatus {
    for (final e in PaymentStatus.values) {
      if (e.firestoreString == this) return e;
    }
    throw ArgumentError('Unknown PaymentStatus value: "$this". Expected one of: ${PaymentStatus.values.map((e) => e.firestoreString).join(", ")}');
  }
}
