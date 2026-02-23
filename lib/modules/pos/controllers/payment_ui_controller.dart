import 'package:get/get.dart';

/// Payment UI state controller
/// Manages UI state for payment screen only (no business logic)
class PaymentUiController extends GetxController {
  // Selected payment method
  final Rxn<String> selectedPaymentMethod = Rxn<String>();

  // Processing state
  final RxBool isProcessing = false.obs;

  // Shop ID (UI state only, not business logic)
  final Rxn<String> shopId = Rxn<String>();

  // User ID (UI state only, not business logic)
  final Rxn<String> userId = Rxn<String>();

  /// Set selected payment method
  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  /// Clear payment method selection
  void clearPaymentMethod() {
    selectedPaymentMethod.value = null;
  }

  /// Set processing state
  void setProcessing(bool value) {
    isProcessing.value = value;
  }

  /// Set shop ID (for UI display purposes)
  void setShopId(String? id) {
    shopId.value = id;
  }

  /// Set user ID (for UI display purposes)
  void setUserId(String? id) {
    userId.value = id;
  }

  @override
  void onClose() {
    selectedPaymentMethod.value = null;
    isProcessing.value = false;
    super.onClose();
  }
}
