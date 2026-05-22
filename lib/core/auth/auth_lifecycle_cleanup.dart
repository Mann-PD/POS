import 'dart:async';

import 'package:get/get.dart';

import '../firestore/firestore_stream_cache.dart';
import '../../modules/pos/controllers/cart_controller.dart';

/// Resets in-memory auth-bound caches and UI controllers on logout / session end.
///
/// Does not run during normal navigation. Call from [AuthController.signOut],
/// login rejection paths, and when Firebase auth reports no user.
class AuthLifecycleCleanup {
  AuthLifecycleCleanup._();

  static Future<void> _chain = Future.value();

  /// Full teardown: Firestore stream cache, cart, ephemeral GetX controllers.
  static Future<void> run() {
    _chain = _chain.then((_) => _runBody());
    return _chain;
  }

  static Future<void> _runBody() async {
    FirestoreStreamCache.instance.clear();

    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().clear();
    }

    await Get.deleteAll(force: true);

    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
  }

  /// Lightweight sync reset when auth stream shows signed-out (idempotent).
  static void onAuthStateSignedOut() {
    FirestoreStreamCache.instance.clear();
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().clear();
    }
  }
}
