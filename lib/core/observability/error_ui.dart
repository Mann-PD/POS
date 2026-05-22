import 'package:flutter/material.dart';

import 'error_reporter.dart';
import 'user_safe_error_mapper.dart';

/// UI-layer helper: report centrally and return a safe user message.
String reportCatch(
  Object error, {
  StackTrace? stackTrace,
  String? tag,
  bool fatal = false,
  Map<String, Object?>? extras,
}) {
  ErrorReporter.instance.report(
    error,
    stackTrace: stackTrace,
    tag: tag,
    fatal: fatal,
    extras: extras,
  );
  return UserSafeErrorMapper.messageFor(error);
}

void showErrorSnackBar(
  BuildContext context,
  Object error, {
  StackTrace? stackTrace,
  String? tag,
  Map<String, Object?>? extras,
}) {
  if (!context.mounted) return;
  final message = reportCatch(
    error,
    stackTrace: stackTrace,
    tag: tag,
    extras: extras,
  );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
