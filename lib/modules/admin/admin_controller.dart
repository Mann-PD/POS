import 'package:get/get.dart';

/// Admin Dashboard UI Controller
/// Manages UI state for admin dashboard only (no business logic)
class AdminController extends GetxController {
  // Loading state for UI operations
  final RxBool isLoading = false.obs;

  /// Set loading state
  void setLoading(bool value) {
    isLoading.value = value;
  }

  @override
  void onClose() {
    isLoading.value = false;
    super.onClose();
  }
}
