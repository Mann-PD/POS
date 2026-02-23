import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/user_model.dart';
import 'expense_controller.dart';

/// Expense Management Screen - Admin view and management of expenses
/// Handles both expense list and expense form
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseController _controller = Get.put(ExpenseController());
  String? _shopId;
  String? _adminUid;
  bool _isLoading = true;

  final List<String> _categories = [
    'Rent',
    'Salary',
    'Utility',
    'Transport',
    'Other',
  ];

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
          _adminUid = user.uid;
          _isLoading = false;
        });
        _controller.setLoading(false);
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
      _controller.setLoading(false);
    }
  }

  Future<void> _saveExpense({
    required String title,
    required String category,
    required double amount,
    String? description,
    required DateTime expenseDate,
  }) async {
    if (_shopId == null || _adminUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop ID or Admin UID not found')),
      );
      return;
    }

    try {
      _controller.setLoading(true);
      // Route through Cloud Function only (schema: expenseId, shopId, amount, description, createdAt)
      final desc = description?.trim().isNotEmpty == true
          ? '$category: $title - $description'
          : '$category: $title';
      final createExpense = FirebaseFunctions.instance.httpsCallable('createExpense');
      await createExpense.call({
        'shopId': _shopId!,
        'amount': amount,
        'description': desc,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Close form bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _controller.setLoading(false);
    }
  }

  void _showExpenseForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExpenseFormBottomSheet(
        categories: _categories,
        onSave: _saveExpense,
      ),
    );
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
            onPressed: _showExpenseForm,
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category filter
                Obx(() => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('all', 'All'),
                          ..._categories.map((cat) => _buildCategoryChip(
                                cat.toLowerCase(),
                                cat,
                              )),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                // Date range filter
                Obx(() => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showDateRangePicker(),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _controller.startDate.value != null
                                  ? '${_controller.startDate.value!.day}/${_controller.startDate.value!.month}/${_controller.startDate.value!.year}'
                                  : 'Start Date',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showDateRangePicker(),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _controller.endDate.value != null
                                  ? '${_controller.endDate.value!.day}/${_controller.endDate.value!.month}/${_controller.endDate.value!.year}'
                                  : 'End Date',
                            ),
                          ),
                        ),
                        if (_controller.startDate.value != null ||
                            _controller.endDate.value != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _controller.clearDateRange(),
                            tooltip: 'Clear Date Range',
                          ),
                      ],
                    )),
              ],
            ),
          ),

          // Expenses list
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
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'expense': ExpenseModel.fromMap(data),
                        'title': data['title'] as String? ?? data['description'] as String? ?? 'Expense',
                        'category': data['category'] as String? ?? 'Other',
                      };
                    })
                    .toList();

                return Obx(() {
                  var filteredExpenses = allExpenses;

                  // Filter by category
                  if (_controller.selectedCategory.value != 'all') {
                    filteredExpenses = filteredExpenses
                        .where((item) =>
                            (item['category'] as String).toLowerCase() ==
                            _controller.selectedCategory.value)
                        .toList();
                  }

                  // Filter by date range
                  if (_controller.startDate.value != null) {
                    filteredExpenses = filteredExpenses.where((item) {
                      final expense = item['expense'] as ExpenseModel;
                      return expense.createdAt
                          .isAfter(_controller.startDate.value!.subtract(
                            const Duration(days: 1),
                          ));
                    }).toList();
                  }

                  if (_controller.endDate.value != null) {
                    filteredExpenses = filteredExpenses.where((item) {
                      final expense = item['expense'] as ExpenseModel;
                      return expense.createdAt
                          .isBefore(_controller.endDate.value!.add(
                            const Duration(days: 1),
                          ));
                    }).toList();
                  }

                  if (filteredExpenses.isEmpty) {
                    return Center(
                      child: Text(
                        'No expenses match your filters',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final item = filteredExpenses[index];
                      final expense = item['expense'] as ExpenseModel;
                      final title = item['title'] as String;
                      final category = item['category'] as String;
                      return _buildExpenseCard(context, expense, title, category);
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(label),
            selected: _controller.selectedCategory.value == value,
            onSelected: (selected) {
              if (selected) {
                _controller.setSelectedCategory(value);
              }
            },
          ),
        ));
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _controller.startDate.value != null &&
              _controller.endDate.value != null
          ? DateTimeRange(
              start: _controller.startDate.value!,
              end: _controller.endDate.value!,
            )
          : null,
    );

    if (picked != null) {
      _controller.setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseModel expense,
    String title,
    String category,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat =
        '${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}';

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
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    category,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: colorScheme.secondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (expense.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                expense.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '₹${expense.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
        ),
      ),
    );
  }
}

/// Expense Form Bottom Sheet
class _ExpenseFormBottomSheet extends StatefulWidget {
  final List<String> categories;
  final Function({
    required String title,
    required String category,
    required double amount,
    String? description,
    required DateTime expenseDate,
  }) onSave;

  const _ExpenseFormBottomSheet({
    required this.categories,
    required this.onSave,
  });

  @override
  State<_ExpenseFormBottomSheet> createState() =>
      _ExpenseFormBottomSheetState();
}

class _ExpenseFormBottomSheetState extends State<_ExpenseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ExpenseController _controller = Get.find<ExpenseController>();
  String _selectedCategory = 'Rent';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _controller.setLoading(true);

    try {
      await widget.onSave(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        expenseDate: _selectedDate,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _controller.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Expense',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Expense Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Amount is required';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Amount must be greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expense Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _titleController.clear();
                            _amountController.clear();
                            _descriptionController.clear();
                            setState(() {
                              _selectedCategory = 'Rent';
                              _selectedDate = DateTime.now();
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Expense'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
