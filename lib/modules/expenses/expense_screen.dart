import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/user_model.dart';
import '../admin/controllers/expense_ui_controller.dart';
import 'expense_form_screen.dart';

/// Expense Management Screen - Admin view of all expenses
/// Allows viewing, adding, and editing expenses
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseUiController _uiController = Get.put(ExpenseUiController());
  String? _shopId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
        );
        setState(() {
          _shopId = userData.shopId;
          _isLoading = false;
        });
        _uiController.setShopId(_shopId);
        _uiController.setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      _uiController.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expenses')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpenseFormScreen(),
                ),
              );
            },
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  if (_uiController.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _uiController.clearSearchQuery(),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _uiController.setSearchQuery(value),
            ),
          ),

          // Expenses list with summary
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .where('shopId', isEqualTo: _shopId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading expenses: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first expense',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                final allExpenses = snapshot.data!.docs
                    .map((doc) => ExpenseModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                        ))
                    .toList();

                // Calculate total expenses
                final totalExpenses = allExpenses.fold<double>(
                  0.0,
                  (sum, expense) => sum + expense.amount,
                );

                return Obx(() {
                  var filteredExpenses = allExpenses;

                  // Filter by search query
                  if (_uiController.searchQuery.value.isNotEmpty) {
                    filteredExpenses = filteredExpenses
                        .where((expense) => expense.description
                            .toLowerCase()
                            .contains(_uiController.searchQuery.value.toLowerCase()))
                        .toList();
                  }

                  // Filter by date if selected
                  if (_uiController.selectedDate.value != null) {
                    final selectedDate = _uiController.selectedDate.value!;
                    filteredExpenses = filteredExpenses.where((expense) {
                      final expenseDate = expense.createdAt;
                      return expenseDate.year == selectedDate.year &&
                          expenseDate.month == selectedDate.month &&
                          expenseDate.day == selectedDate.day;
                    }).toList();
                  }

                  return Column(
                    children: [
                      // Total expenses card
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Expenses',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${totalExpenses.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Expenses list
                      Expanded(
                        child: filteredExpenses.isEmpty
                            ? Center(
                                child: Text(
                                  'No expenses match your filters',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredExpenses.length,
                                itemBuilder: (context, index) {
                                  final expense = filteredExpenses[index];
                                  return _buildExpenseCard(context, expense);
                                },
                              ),
                      ),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, ExpenseModel expense) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = '${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}';
    final timeFormat = '${expense.createdAt.hour.toString().padLeft(2, '0')}:${expense.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.errorContainer,
          child: Icon(
            Icons.account_balance_wallet,
            color: colorScheme.onErrorContainer,
          ),
        ),
        title: Text(expense.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: $dateFormat at $timeFormat'),
          ],
        ),
        trailing: Text(
          '₹${expense.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseFormScreen(expense: expense),
            ),
          );
        },
      ),
    );
  }
}
