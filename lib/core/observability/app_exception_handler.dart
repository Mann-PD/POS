import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'error_reporter.dart';

/// Installs global Flutter/Dart/async error handlers.
class AppExceptionHandler {
  AppExceptionHandler._();

  static Future<void> initialize() async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );
    ErrorReporter.instance.markCrashlyticsReady();

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
      ErrorReporter.instance.report(
        details.exception,
        stackTrace: details.stack,
        tag: 'FlutterError',
        fatal: true,
      );
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      ErrorReporter.instance.report(
        error,
        stackTrace: stack,
        tag: 'PlatformDispatcher',
        fatal: true,
      );
      return true;
    };
  }

  /// Wraps [runApp] zone for uncaught async errors outside Flutter framework.
  static R runZonedApp<R>(R Function() body, {void Function()? onZoneError}) {
    return runZonedGuarded<R>(
      body,
      (Object error, StackTrace stack) {
        ErrorReporter.instance.report(
          error,
          stackTrace: stack,
          tag: 'runZonedGuarded',
          fatal: true,
        );
        onZoneError?.call();
      },
    )!;
  }
}
