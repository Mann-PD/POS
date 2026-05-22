import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/user_model.dart';
import 'reports_service.dart';

/// Product Sales Report
/// Shows quantity sold and total revenue per product for a date range.
class ProductSalesReportScreen extends StatefulWidget {
  const ProductSalesReportScreen({super.key});

  @override
  State<ProductSalesReportScreen> createState() =>
      _ProductSalesReportScreenState();
}

class _ProductSalesReportScreenState
    extends State<ProductSalesReportScreen> {
  final ReportsService _reports = ReportsService();

  String? _shopId;
  bool _loadingUser = true;
  bool _loadingData = false;
  List<ProductSalesRow> _rows = const [];
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

      final rows = await _reports.getProductSales(
        start: start,
        end: end,
        shopId: _shopId,
      );
      setState(() {
        _rows = rows;
        _loadingData = false;
      });
    } catch (e) {
      setState(() {
        _loadingData = false;
        _error = 'Failed to load product sales: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Sales Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Sales Report')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_shopId == null || _shopId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Sales Report')),
        body: const Center(child: Text('Shop not assigned')),
      );
    }

    final rangeText = _range == null
        ? 'No range selected'
        : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year}'
          ' - '
          '${_range!.end.day}/${_range!.end.month}/${_range!.end.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Sales Report'),
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
            Expanded(
              child: _loadingData
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                      ? const Center(
                          child:
                              Text('No product sales in selected range'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rows.length,
                          itemBuilder: (context, index) {
                            final row = _rows[index];
                            return Card(
                              margin:
                                  const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(row.name),
                                subtitle: Text(
                                  'Qty: ${row.quantity.toStringAsFixed(2)}',
                                ),
                                trailing: Text(
                                  '₹${row.total.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

