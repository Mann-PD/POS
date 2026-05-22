import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/observability/app_logger.dart';
import '../data/models/user_model.dart';
import '../modules/authentication/login_screen.dart';
import '../modules/pos/pos_home_screen.dart';
import '../modules/admin/admin_dashboard.dart';
import '../modules/super_admin/super_admin_dashboard.dart';
import '../modules/reports/viewer_reports_dashboard.dart';
import 'app_routes.dart';
import 'auth_scope.dart';
import 'permission_gate.dart';
import 'role_based_router.dart';
import 'screen_permission.dart';

/// Route guard enforced on every named navigation.
///
/// Rules:
/// 1. Public routes (/login) are always allowed.
/// 2. All protected routes MUST carry a [UserModel] as [RouteSettings.arguments].
///    The [AuthWrapper] sets this when it calls [Navigator.pushReplacementNamed].
/// 3. The authenticated user's role must be in [RoleBasedRouter.allowedRoles]
///    for the requested route. Any mismatch → redirect to login.
/// 4. If Firebase Auth reports no current user → redirect to login.
/// 5. Unknown routes → redirect to login (fail-safe default).
///
/// This guard runs synchronously inside [onGenerateRoute], so it does NOT
/// perform any async Firestore calls. The [UserModel] is provided by the
/// already-authenticated [AuthWrapper] as route arguments.
class RouteGuard {
  RouteGuard._();

  /// Plug this directly into [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? AppRoutes.login;

    // ── Public routes — no guard needed ──────────────────────────────────────
    if (routeName == AppRoutes.login) {
      return _buildRoute(settings, const LoginScreen());
    }

    // ── Protected routes ─────────────────────────────────────────────────────

    // 1. Firebase Auth must have a current user.
    if (FirebaseAuth.instance.currentUser == null) {
      AppLogger.debug(
        'No authenticated user → redirect to login (attempted: $routeName)',
        tag: 'RouteGuard',
      );
      return _redirectToLogin(settings);
    }

    // 2. A UserModel must have been passed as arguments by the caller
    //    (AuthWrapper / LoginScreen pass it via pushReplacementNamed(..., arguments: user)).
    final args = settings.arguments;
    if (args == null || args is! UserModel) {
      AppLogger.debug(
        'Missing or invalid UserModel arguments → redirect to login '
        '(attempted: $routeName)',
        tag: 'RouteGuard',
      );
      return _redirectToLogin(settings);
    }

    final UserModel user = args;

    AppLogger.debug(
      'Validating route "$routeName" for role "${user.role}"',
      tag: 'RouteGuard',
    );
    final String role = user.role;

    // 3. Role must be valid.
    if (!RoleBasedRouter.isValidRole(role)) {
      AppLogger.warning(
        'Unrecognised role "$role" → redirect to login',
        tag: 'RouteGuard',
      );
      return _redirectToLogin(settings);
    }

    // 4. Role must be permitted on this specific route.
    final allowed = RoleBasedRouter.allowedRoles(routeName);
    if (allowed.isEmpty || !allowed.contains(role)) {
      AppLogger.warning(
        'Role "$role" not allowed on "$routeName" (allowed: $allowed) → login',
        tag: 'RouteGuard',
      );
      return _redirectToLogin(settings);
    }

    // ── All checks passed — build the requested page ──────────────────────
    final Widget page = _pageForRoute(routeName, user);
    return _buildRoute(
      settings,
      AuthScope(
        user: user,
        child: PermissionGate(
          permission: _permissionForRoute(routeName),
          child: page,
        ),
      ),
    );
  }

  static ScreenPermission _permissionForRoute(String route) {
    switch (route) {
      case AppRoutes.employee:
      case AppRoutes.employeeDashboard:
        return ScreenPermission.posHome;
      case AppRoutes.admin:
      case AppRoutes.adminDashboard:
        return ScreenPermission.adminDashboard;
      case AppRoutes.superAdmin:
      case AppRoutes.superAdminDashboard:
        return ScreenPermission.superAdminDashboard;
      case AppRoutes.viewer:
      case AppRoutes.viewerDashboard:
        return ScreenPermission.reportsDashboard;
      default:
        return ScreenPermission.public;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Widget _pageForRoute(String route, UserModel user) {
    switch (route) {
      case AppRoutes.employee:
      case AppRoutes.employeeDashboard:
        return const PosHomeScreen();

      case AppRoutes.admin:
      case AppRoutes.adminDashboard:
        return const AdminDashboard();

      case AppRoutes.superAdmin:
      case AppRoutes.superAdminDashboard:
        return const SuperAdminDashboard();

      case AppRoutes.viewer:
      case AppRoutes.viewerDashboard:
        return const ViewerReportsDashboard();

      default:
        // Should never reach here after the allowed-roles check, but
        // fail safe: send to login rather than crash.
        AppLogger.warning('Unknown route "$route" → login', tag: 'RouteGuard');
        return const LoginScreen();
    }
  }

  /// Returns a named route that shows [page].
  static MaterialPageRoute<dynamic> _buildRoute(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => page,
    );
  }

  /// Returns a route that replaces the current route with [LoginScreen].
  static MaterialPageRoute<dynamic> _redirectToLogin(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: AppRoutes.login),
      builder: (_) => const LoginScreen(),
    );
  }
}
