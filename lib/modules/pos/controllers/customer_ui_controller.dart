import 'package:get/get.dart';

/// Customer UI state controller
/// Manages UI state for customer screen only (no business logic)
class CustomerUiController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

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
