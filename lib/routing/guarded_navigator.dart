import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import 'app_routes.dart';
import 'auth_scope.dart';
import 'permission_gate.dart';
import 'screen_permission.dart';

/// Centralized RBAC-safe navigation for sub-screens.
///
/// Validates role before pushing; wraps destination in [PermissionGate].
class GuardedNavigator {
  GuardedNavigator._();

  static UserModel? _currentUser(BuildContext context) {
    final fromScope = AuthScope.maybeOf(context);
    if (fromScope != null) return fromScope;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel) return args;

    return null;
  }

  static bool _canNavigate(BuildContext context, ScreenPermission permission) {
    if (permission == ScreenPermission.public) return true;
    if (FirebaseAuth.instance.currentUser == null) return false;

    final user = _currentUser(context);
    if (user == null) return false;

    return ScreenPermissionPolicy.isAllowed(user.role, permission);
  }

  static void _deny(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to access this screen.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void _redirectLogin(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Pushes [page] when [permission] allows the current user's role.
  static Future<T?> push<T>(
    BuildContext context, {
    required ScreenPermission permission,
    required Widget page,
  }) {
    if (!_canNavigate(context, permission)) {
      if (FirebaseAuth.instance.currentUser == null) {
        _redirectLogin(context);
      } else {
        _deny(context);
      }
      return Future.value(null);
    }

    final user = _currentUser(context);
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (ctx) {
          Widget child = PermissionGate(
            permission: permission,
            child: page,
          );
          if (user != null) {
            child = AuthScope(user: user, child: child);
          }
          return child;
        },
      ),
    );
  }

  /// Replaces current route with [page] when permitted.
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context, {
    required ScreenPermission permission,
    required Widget page,
    TO? result,
  }) {
    if (!_canNavigate(context, permission)) {
      if (FirebaseAuth.instance.currentUser == null) {
        _redirectLogin(context);
      } else {
        _deny(context);
      }
      return Future.value(null);
    }

    final user = _currentUser(context);
    return Navigator.of(context).pushReplacement<T, TO>(
      MaterialPageRoute<T>(
        builder: (ctx) {
          Widget child = PermissionGate(
            permission: permission,
            child: page,
          );
          if (user != null) {
            child = AuthScope(user: user, child: child);
          }
          return child;
        },
      ),
      result: result,
    );
  }

  /// Clears the stack and shows [page] when permitted (e.g. return to POS home).
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context, {
    required ScreenPermission permission,
    required Widget page,
  }) {
    if (!_canNavigate(context, permission)) {
      if (FirebaseAuth.instance.currentUser == null) {
        _redirectLogin(context);
      } else {
        _deny(context);
      }
      return Future.value(null);
    }

    final user = _currentUser(context);
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (ctx) {
          Widget child = PermissionGate(
            permission: permission,
            child: page,
          );
          if (user != null) {
            child = AuthScope(user: user, child: child);
          }
          return child;
        },
      ),
      (route) => false,
    );
  }

  /// Pushes a public (unauthenticated) screen such as forgot password.
  static Future<T?> pushPublic<T>(
    BuildContext context, {
    required Widget page,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => PermissionGate(
          permission: ScreenPermission.public,
          child: page,
        ),
      ),
    );
  }
}
