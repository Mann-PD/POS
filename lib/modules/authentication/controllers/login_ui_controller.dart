import 'package:get/get.dart';

/// Login UI state controller
/// Manages UI state for login screen only (no business logic)
class LoginUiController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

  // Password visibility
  final RxBool obscurePassword = true.obs;

  // Error message
  final Rxn<String> errorMessage = Rxn<String>();

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Set loading state
  void setLoading(bool value) {
    isLoading.value = value;
  }

  /// Set error message
  void setError(String? message) {
    errorMessage.value = message;
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = null;
  }

  @override
  void onClose() {
    clearError();
    super.onClose();
  }
}
