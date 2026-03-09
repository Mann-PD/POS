import 'role_constants.dart';

/// Simple UI-only permission helpers.
/// Firestore security rules remain the final authority for access control.
class PermissionChecker {
  static bool canAccessPOS(String role) {
    return role == RoleConstants.employee;
  }

  static bool canAccessAdmin(String role) {
    return role == RoleConstants.admin ||
        role == RoleConstants.superAdmin;
  }

  static bool canAccessSuperAdmin(String role) {
    return role == RoleConstants.superAdmin;
  }

  static bool canViewReports(String role) {
    return role == RoleConstants.admin ||
        role == RoleConstants.superAdmin ||
        role == RoleConstants.viewer;
  }
}

