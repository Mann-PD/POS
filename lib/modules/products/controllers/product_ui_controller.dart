import 'package:get/get.dart';

/// Product UI state controller
/// Manages UI state for product screens only (no business logic)
class ProductUiController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

  // Search query for product list
  final RxString searchQuery = ''.obs;

  // Selected filter/category
  final RxString selectedFilter = 'all'.obs;

  /// Set loading state
  void setLoading(bool value) {
    isLoading.value = value;
  }

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clear search query
  void clearSearchQuery() {
    searchQuery.value = '';
  }

  /// Set selected filter
  void setSelectedFilter(String filter) {
    selectedFilter.value = filter;
  }

  @override
  void onClose() {
    searchQuery.value = '';
    selectedFilter.value = 'all';
    super.onClose();
  }
}
