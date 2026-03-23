import 'app_routes.dart';

/// Maps user roles to routes and validates role→route access.
///
/// Role strings use canonical Firestore values: 'SuperAdmin', 'Admin',
/// 'Employee', 'Viewer'.
class RoleBasedRouter {
  RoleBasedRouter._();

  // ── Role → initial route ──────────────────────────────────────────────────

  /// Returns the canonical initial route for [role].
  /// Throws [ArgumentError] for an empty or unrecognised role.
  static String getInitialRoute(String role) {
    if (role.isEmpty) {
      throw ArgumentError.value(role, 'role', 'Role cannot be empty');
    }

    final normalised = role.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');
    switch (normalised) {
      case 'employee':
        return AppRoutes.employee;
      case 'admin':
        return AppRoutes.admin;
      case 'superadmin':
        return AppRoutes.superAdmin;
      case 'viewer':
        return AppRoutes.viewer;
      default:
        throw ArgumentError.value(
          role,
          'role',
          'Unrecognised role. Supported: SuperAdmin, Admin, Employee, Viewer',
        );
    }
  }

  // ── Route → allowed roles ─────────────────────────────────────────────────

  /// Returns the set of canonical role strings permitted to access [route].
  /// Returns an empty set for public/unknown routes (they are handled separately).
  static Set<String> allowedRoles(String route) {
    switch (route) {
      case AppRoutes.employee:
      case AppRoutes.employeeDashboard:
        return {'Employee'};

      case AppRoutes.admin:
      case AppRoutes.adminDashboard:
        return {'Admin'};

      case AppRoutes.superAdmin:
      case AppRoutes.superAdminDashboard:
        return {'SuperAdmin'};

      case AppRoutes.viewer:
      case AppRoutes.viewerDashboard:
        return {'Viewer', 'Admin', 'SuperAdmin'};

      default:
        return {};
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true if [role] is a recognised, non-empty role string.
  static bool isValidRole(String role) {
    if (role.isEmpty) return false;
    try {
      getInitialRoute(role);
      return true;
    } catch (_) {
      return false;
    }
  }
}
