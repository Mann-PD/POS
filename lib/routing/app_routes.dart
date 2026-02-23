/// Application route names
/// 
/// This file defines all route names used throughout the application.
/// Route names should be used consistently to avoid typos and ensure
/// type safety when navigating.
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  /// Authentication routes
  static const String login = '/login';

  /// Dashboard routes
  /// 
  /// Each role has its own dashboard route:
  /// - Employee: POS home (billing interface)
  /// - Admin: Admin dashboard (shop management)
  /// - Super Admin: Super Admin dashboard (system-wide management)
  /// - Viewer: Viewer dashboard
  static const String employeeDashboard = '/employee-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String superAdminDashboard = '/super-admin-dashboard';
  static const String viewerDashboard = '/viewer-dashboard';
}
