import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages per-device session identifiers for concurrent-login control.
class SessionManager {
  static const _prefsKeyPrefix = 'active_session_';

  /// Returns existing sessionId for this user on this device, or creates a new one.
  static Future<String> getOrCreateSessionId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsKeyPrefix$userId';
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = Random();
    final newId =
        '$userId-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1 << 32)}';
    await prefs.setString(key, newId);
    return newId;
  }

  /// Register (or refresh) the active session in backend. Best-effort only.
  static Future<void> registerActiveSession(String userId) async {
    try {
      final sessionId = await getOrCreateSessionId(userId);
      final callable =
          FirebaseFunctions.instance.httpsCallable('setActiveSession');
      await callable.call(<String, dynamic>{
        'sessionId': sessionId,
      });
    } catch (_) {
      // Non-blocking; concurrent-login restriction is best-effort.
    }
  }

  /// Validates that this device is the active session for the given user.
  /// Returns true if either no remote session is set, or it matches local id.
  static Future<bool> isCurrentDeviceActive(
    String userId,
    String? remoteSessionId,
  ) async {
    if (remoteSessionId == null || remoteSessionId.isEmpty) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsKeyPrefix$userId';
    final local = prefs.getString(key);
    if (local == null || local.isEmpty) {
      return false;
    }
    return local == remoteSessionId;
  }
}

