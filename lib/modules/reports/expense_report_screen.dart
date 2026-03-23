import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/user_model.dart';
import 'reports_service.dart';

/// Expense Report Screen
/// Shows total expenses, category breakdown, and supports date range filtering.
class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  final ReportsService _reports = ReportsService();

  String? _shopId;
  bool _loadingUser = true;
  bool _loadingData = false;
  ExpenseSummary? _summary;
  DateTimeRange? _range;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loadingUser = false;
          _error = 'User not authenticated';
        });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists || doc.data() == null) {
        setState(() {
          _loadingUser = false;
          _error = 'User document not found';
        });
        return;
      }
      final u = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      final now = DateTime.now();
      final initialRange = DateTimeRange(
        start: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 30)),
        end: DateTime(now.year, now.month, now.day),
      );
      setState(() {
        _shopId = u.shopId;
        _loadingUser = false;
        _range = initialRange;
      });
      await _loadData();
    } catch (e) {
      setState(() {
        _loadingUser = false;
        _error = 'Failed to load user: $e';
      });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
      });
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_shopId == null || _shopId!.isEmpty || _range == null) return;
    setState(() {
      _loadingData = true;
      _error = null;
    });

    try {
      final start = DateTime(
        _range!.start.year,
        _range!.start.month,
        _range!.start.day,
      );
      final end = DateTime(
        _range!.end.year,
        _range!.end.month,
        _range!.end.day,
        23,
        59,
        59,
      );

      final summary = await _reports.getExpenseSummary(
        start: start,
        end: end,
        shopId: _shopId,
      );
      setState(() {
        _summary = summary;
        _loadingData = false;
      });
    } catch (e) {
      setState(() {
        _loadingData = false;
        _error = 'Failed to load expense summary: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Report')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_shopId == null || _shopId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Report')),
        body: const Center(child: Text('Shop not assigned')),
      );
    }

    final rangeText = _range == null
        ? 'No range selected'
        : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year}'
          ' - '
          '${_range!.end.day}/${_range!.end.month}/${_range!.end.year}';

    final summary = _summary ?? ExpenseSummary.empty();
    final expenses = summary.expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Report'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(rangeText),
              ),
            ),
            if (_loadingData)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TotalCard(
                        total: summary.totalExpenses,
                        count: expenses.length,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'By Category',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (summary.byCategory.isEmpty)
                        const Text('No expenses in selected range')
                      else
                        ...summary.byCategory.entries.map((e) {
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.category),
                              title: Text(e.key),
                              trailing: Text(
                                '₹${e.value.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      Text(
                        'Recent Expenses',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (expenses.isEmpty)
                        const Text('No expenses to display')
                      else
                        ...expenses.take(30).map(
                          (e) => Card(
                            margin:
                                const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                e.description.isNotEmpty
                                    ? e.description
                                    : 'Expense',
                              ),
                              subtitle: Text(
                                '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}'
                                ' • ${e.category}',
                              ),
                              trailing: Text(
                                '₹${e.amount.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.count,
  });

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: colorScheme.onErrorContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                  Text(
                    '$count entries',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

