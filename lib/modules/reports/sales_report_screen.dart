import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/user_model.dart';
import 'reports_service.dart';

/// Sales Report Screen
/// Admin can select a date range and view:
/// - total sales
/// - total orders
/// - average order value
/// - payment method breakdown
class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final ReportsService _reports = ReportsService();

  String? _shopId;
  bool _loadingUser = true;
  bool _loadingSummary = false;
  SalesSummary? _summary;
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
      final u = UserModel.tryFromDocument(doc);
      if (u == null) {
        setState(() {
          _loadingUser = false;
          _error = 'User document invalid';
        });
        return;
      }
      final now = DateTime.now();
      final initialRange = DateTimeRange(
        start: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6)),
        end: DateTime(now.year, now.month, now.day),
      );
      setState(() {
        _shopId = u.shopId;
        _loadingUser = false;
        _range = initialRange;
      });
      await _loadSummary();
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
      await _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    if (_shopId == null || _shopId!.isEmpty || _range == null) return;
    setState(() {
      _loadingSummary = true;
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

      final summary = await _reports.getSalesSummary(
        start: start,
        end: end,
        shopId: _shopId,
      );
      setState(() {
        _summary = summary;
        _loadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _loadingSummary = false;
        _error = 'Failed to load sales summary: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loadingUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Report')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_shopId == null || _shopId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Report')),
        body: const Center(child: Text('Shop not assigned')),
      );
    }

    final summary = _summary ?? SalesSummary.empty();
    final rangeText = _range == null
        ? 'No range selected'
        : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year}'
          ' - '
          '${_range!.end.day}/${_range!.end.month}/${_range!.end.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(rangeText),
              ),
              const SizedBox(height: 16),
              if (_loadingSummary)
                const Center(child: CircularProgressIndicator())
              else ...[
                _SummaryCard(
                  title: 'Total Sales',
                  value: '₹${summary.totalSales.toStringAsFixed(2)}',
                  subtitle: '${summary.totalOrders} orders',
                  icon: Icons.currency_rupee,
                  valueColor: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  title: 'Average Order Value',
                  value: '₹${summary.averageOrderValue.toStringAsFixed(2)}',
                  subtitle: summary.totalOrders == 0
                      ? 'No orders in range'
                      : 'Based on ${summary.totalOrders} orders',
                  icon: Icons.analytics,
                  valueColor: colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment Method Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (summary.paymentMethodCounts.isEmpty)
                  const Text('No data for selected range')
                else
                  ...summary.paymentMethodCounts.entries.map((entry) {
                    final method = entry.key;
                    final count = entry.value;
                    final amount =
                        summary.paymentMethodAmounts[method] ?? 0.0;
                    final methodLabel =
                        method.isEmpty || method == 'unknown'
                            ? 'Unknown'
                            : method.toUpperCase();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.payment),
                        title: Text(methodLabel),
                        subtitle: Text('$count orders'),
                        trailing: Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.valueColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = valueColor ?? colorScheme.primary;

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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
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

