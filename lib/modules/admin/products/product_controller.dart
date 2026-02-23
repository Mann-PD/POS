import 'package:get/get.dart';

/// Product UI Controller
/// Manages UI state for product management screens only (no business logic)
class ProductController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

  // Search query for product list
  final RxString searchQuery = ''.obs;

  // Selected filter (all, active, inactive)
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
