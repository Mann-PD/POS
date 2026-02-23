import 'package:get/get.dart';

/// Employee Management UI state controller
/// Manages UI state for employee management screens only (no business logic)
class EmployeeUiController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

  // Search query for employee list
  final RxString searchQuery = ''.obs;

  // Selected filter (all, active, inactive)
  final RxString selectedFilter = 'all'.obs;

  // Shop ID (UI state only, not business logic)
  final Rxn<String> shopId = Rxn<String>();

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

  /// Set shop ID (for UI display purposes)
  void setShopId(String? id) {
    shopId.value = id;
  }

  @override
  void onClose() {
    searchQuery.value = '';
    selectedFilter.value = 'all';
    super.onClose();
  }
}
