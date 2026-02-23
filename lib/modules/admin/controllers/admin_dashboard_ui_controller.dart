import 'package:get/get.dart';

/// Admin Dashboard UI state controller
/// Manages UI state for admin dashboard only (no business logic)
class AdminDashboardUiController extends GetxController {
  // Loading state
  final RxBool isLoading = true.obs;

  // Shop ID (UI state only, not business logic)
  final Rxn<String> shopId = Rxn<String>();

  /// Set loading state
  void setLoading(bool value) {
    isLoading.value = value;
  }

  /// Set shop ID (for UI display purposes)
  void setShopId(String? id) {
    shopId.value = id;
  }

  @override
  void onClose() {
    isLoading.value = false;
    super.onClose();
  }
}
