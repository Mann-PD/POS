/// Application route names.
///
/// Protected routes require a valid authenticated user whose role matches.
/// The guard is enforced in [RouteGuard.onGenerateRoute].
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // ── Authentication ────────────────────────────────────────────────────────
  static const String login = '/login';

  // ── Protected dashboard routes ────────────────────────────────────────────
  // Canonical short forms (per requirements)
  static const String employee    = '/employee';
  static const String admin       = '/admin';
  static const String superAdmin  = '/super_admin';
  static const String viewer      = '/viewer';

  // Legacy long-form aliases (kept for backwards compatibility)
  static const String employeeDashboard    = '/employee-dashboard';
  static const String adminDashboard       = '/admin-dashboard';
  static const String superAdminDashboard  = '/super-admin-dashboard';
  static const String viewerDashboard      = '/viewer-dashboard';

  /// All route names that require authentication and role validation.
  static const List<String> protectedRoutes = [
    employee,
    admin,
    superAdmin,
    viewer,
    employeeDashboard,
    adminDashboard,
    superAdminDashboard,
    viewerDashboard,
  ];
}
