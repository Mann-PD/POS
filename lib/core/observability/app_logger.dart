import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'log_redactor.dart';

/// Environment-aware structured logging.
///
/// - Debug/profile: [developer.log] with full detail.
/// - Release: breadcrumbs via Crashlytics; no verbose console noise.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag, Object? error}) {
    if (!kDebugMode) return;
    developer.log(
      LogRedactor.sanitize(message),
      name: tag ?? 'app',
      error: error,
    );
  }

  static void info(String message, {String? tag}) {
    final text = LogRedactor.sanitize(message);
    if (kDebugMode) {
      developer.log(text, name: tag ?? 'app');
    } else {
      FirebaseCrashlytics.instance.log('${tag ?? 'app'}: $text');
    }
  }

  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final text = LogRedactor.sanitize(message);
    developer.log(
      text,
      name: tag ?? 'app',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log('WARN ${tag ?? 'app'}: $text');
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final text = LogRedactor.sanitize(message);
    developer.log(
      text,
      name: tag ?? 'app',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (kReleaseMode && error != null) {
      FirebaseCrashlytics.instance.log('ERROR ${tag ?? 'app'}: $text');
    }
  }
}
