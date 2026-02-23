import 'package:get/get.dart';

/// Expense Management UI state controller
/// Manages UI state for expense management screens only (no business logic)
class ExpenseUiController extends GetxController {
  // Loading state
  final RxBool isLoading = false.obs;

  // Search query for expense list
  final RxString searchQuery = ''.obs;

  // Selected date filter
  final Rxn<DateTime> selectedDate = Rxn<DateTime>();

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

  /// Set selected date
  void setSelectedDate(DateTime? date) {
    selectedDate.value = date;
  }

  /// Clear selected date
  void clearSelectedDate() {
    selectedDate.value = null;
  }

  /// Set shop ID (for UI display purposes)
  void setShopId(String? id) {
    shopId.value = id;
  }

  @override
  void onClose() {
    searchQuery.value = '';
    selectedDate.value = null;
    super.onClose();
  }
}
