import 'app_routes.dart';

/// Role-based router for determining initial route based on user role
/// 
/// This router maps user roles to their corresponding dashboard routes.
/// It handles role string normalization to support various input formats.
class RoleBasedRouter {
  RoleBasedRouter._(); // Private constructor to prevent instantiation

  /// Determines the initial route based on user role
  /// 
  /// [role] - The user's role string (case-insensitive, supports various formats)
  /// 
  /// Returns the route string for the user's dashboard:
  /// - 'employee' → Employee dashboard (POS home)
  /// - 'admin' → Admin dashboard
  /// - 'super_admin' → Super Admin dashboard
  /// - 'viewer' → Viewer dashboard
  ///
  /// Accepts standard role values (case-insensitive): super_admin, admin, employee, viewer.
  /// 
  /// Throws [ArgumentError] if role is null, empty, or unrecognized
  static String getInitialRoute(String role) {
    if (role.isEmpty) {
      throw ArgumentError.value(
        role,
        'role',
        'Role cannot be empty',
      );
    }

    // Normalize: lowercase, collapse underscores/hyphens/spaces
    final normalizedRole = role.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');

    switch (normalizedRole) {
      case 'employee':
        return AppRoutes.employeeDashboard;

      case 'admin':
        return AppRoutes.adminDashboard;

      case 'superadmin':
        return AppRoutes.superAdminDashboard;

      case 'viewer':
        return AppRoutes.viewerDashboard;

      default:
        throw ArgumentError.value(
          role,
          'role',
          'Unrecognized role. Supported roles: super_admin, admin, employee, viewer',
        );
    }
  }

  /// Checks if a role is valid
  /// 
  /// [role] - The role string to validate
  /// 
  /// Returns true if the role is recognized, false otherwise
  static bool isValidRole(String role) {
    if (role.isEmpty) {
      return false;
    }

    try {
      getInitialRoute(role);
      return true;
    } catch (e) {
      return false;
    }
  }
}
