import 'package:get/get.dart';

/// Inventory UI Controller
/// Manages UI state for inventory management screen only (no business logic)
class InventoryController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

  // Search query for inventory list
  final RxString searchQuery = ''.obs;

  // Selected filter (all, active, inactive, low-stock, out-of-stock)
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
