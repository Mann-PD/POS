import 'package:flutter/material.dart';
import '../data/models/user_model.dart';

/// Provides the authenticated [UserModel] to the widget tree below a
/// [RouteGuard]-protected dashboard.
class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.user,
    required super.child,
  });

  final UserModel user;

  static UserModel? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    return scope?.user;
  }

  static UserModel of(BuildContext context) {
    final user = maybeOf(context);
    assert(user != null, 'AuthScope not found in widget tree');
    return user!;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      oldWidget.user.userId != user.userId ||
      oldWidget.user.role != user.role ||
      oldWidget.user.shopId != user.shopId;
}
