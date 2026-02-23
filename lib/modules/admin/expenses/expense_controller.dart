import 'package:get/get.dart';

/// Expense UI Controller
/// Manages UI state for expense management screen only (no business logic)
class ExpenseController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

  // Search query for expense list
  final RxString searchQuery = ''.obs;

  // Selected category filter (all, rent, salary, utility, transport, other)
  final RxString selectedCategory = 'all'.obs;

  // Selected date range
  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

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

  /// Set selected category
  void setSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  /// Set date range
  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
  }

  /// Clear date range
  void clearDateRange() {
    startDate.value = null;
    endDate.value = null;
  }

  @override
  void onClose() {
    searchQuery.value = '';
    selectedCategory.value = 'all';
    startDate.value = null;
    endDate.value = null;
    super.onClose();
  }
}
