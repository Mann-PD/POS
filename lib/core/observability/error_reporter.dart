import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app_logger.dart';
import 'log_redactor.dart';

/// Single entry point for recording errors to logs and Crashlytics.
class ErrorReporter {
  ErrorReporter._();

  static final ErrorReporter instance = ErrorReporter._();

  bool _crashlyticsReady = false;

  void markCrashlyticsReady() {
    _crashlyticsReady = true;
  }

  Future<void> report(
    Object error, {
    StackTrace? stackTrace,
    String? tag,
    bool fatal = false,
    Map<String, Object?>? extras,
  }) async {
    final label = tag ?? 'app';
    final detail = error.toString();
    AppLogger.error(
      detail,
      tag: label,
      error: error,
      stackTrace: stackTrace,
    );

    if (!_crashlyticsReady) return;

    try {
      if (extras != null && extras.isNotEmpty) {
        final safe = LogRedactor.sanitizeMap(extras);
        for (final entry in safe.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(
            entry.key,
            entry.value?.toString() ?? '',
          );
        }
      }
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: LogRedactor.sanitize('$label: $detail'),
        fatal: fatal,
      );
    } catch (e, st) {
      AppLogger.warning(
        'Crashlytics recordError failed',
        tag: 'ErrorReporter',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> setUserContext({
    String? userId,
    String? role,
    String? shopId,
  }) async {
    if (!_crashlyticsReady) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
      if (role != null) {
        await FirebaseCrashlytics.instance.setCustomKey('role', role);
      }
      if (shopId != null) {
        await FirebaseCrashlytics.instance.setCustomKey('shopId', shopId);
      }
    } catch (_) {
      // Non-blocking
    }
  }

  Future<void> clearUserContext() async {
    if (!_crashlyticsReady) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      await FirebaseCrashlytics.instance.setCustomKey('role', '');
      await FirebaseCrashlytics.instance.setCustomKey('shopId', '');
    } catch (_) {
      // Non-blocking
    }
  }
}
