import 'dart:async';

import 'package:flutter/material.dart';
import 'auth_controller.dart';

/// Wraps authenticated area and enforces session timeout based on user inactivity.
/// Any tap/move resets the timer; on timeout, logs out and returns to login.
class InactivityWrapper extends StatefulWidget {
  const InactivityWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 30),
  });

  final Widget child;
  final Duration timeout;

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetTimer() {
    _cancelTimer();
    _timer = Timer(widget.timeout, _onTimeout);
  }

  Future<void> _onTimeout() async {
    _cancelTimer();
    await AuthController().signOut();
    if (!mounted) return;
    if (!Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired due to inactivity'),
      ),
    );
  }

  void _handleUserInteraction([PointerEvent? _]) {
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerSignal: _handleUserInteraction,
      child: widget.child,
    );
  }
}

