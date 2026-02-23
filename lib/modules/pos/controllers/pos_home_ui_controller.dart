import 'package:get/get.dart';

/// POS Home UI state controller
/// Manages UI state for POS home screen only (no business logic)
class PosHomeUiController extends GetxController {
  // Search query
  final RxString searchQuery = ''.obs;

  // Selected category
  final RxString selectedCategory = 'all'.obs;

  // Loading state
  final RxBool isLoading = true.obs;

  // Shop ID (UI state only, not business logic)
  final Rxn<String> shopId = Rxn<String>();

  // User ID (UI state only, not business logic)
  final Rxn<String> userId = Rxn<String>();

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clear search query
  void clearSearchQuery() {
    searchQuery.value = '';
  }

  /// Set selected category
  void setSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  /// Set loading state
  void setLoading(bool value) {
    isLoading.value = value;
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
    searchQuery.value = '';
    selectedCategory.value = 'all';
    super.onClose();
  }
}
