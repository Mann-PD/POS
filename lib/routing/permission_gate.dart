import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import 'app_routes.dart';
import 'auth_scope.dart';
import 'screen_permission.dart';

/// Runtime RBAC gate for sub-screens. Blocks build when role is not permitted.
///
/// Use on screens that can be reached via [MaterialPageRoute] or embedded in
/// tabs, so UI hiding alone cannot bypass authorization.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final ScreenPermission permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (permission == ScreenPermission.public) {
      return child;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      return fallback ?? const _AccessDenied();
    }

    final UserModel? user = _resolveUser(context);
    if (user == null || !ScreenPermissionPolicy.isAllowed(user.role, permission)) {
      return fallback ?? const _AccessDenied();
    }

    return AuthScope(user: user, child: child);
  }

  static UserModel? _resolveUser(BuildContext context) {
    final fromScope = AuthScope.maybeOf(context);
    if (fromScope != null) return fromScope;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel) return args;

    return null;
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'You do not have permission to view this screen.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
