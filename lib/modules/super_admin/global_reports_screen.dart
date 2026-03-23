import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/order_model.dart';
import '../../data/models/shop_model.dart';
import '../reports/reports_service.dart';

/// Super Admin: cross-shop analytics.
/// Shows total sales across all shops, total orders, and top performing shops.
class GlobalReportsScreen extends StatelessWidget {
  GlobalReportsScreen({super.key});

  final ReportsService _reports = ReportsService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Reports'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _reports.streamLockedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('No locked orders found in the system.'),
            );
          }

          double totalSales = 0;
          final Map<String, _ShopAgg> byShop = {};

          for (final o in orders) {
            totalSales += o.totalAmount;
            final id = o.shopId;
            final existing = byShop[id];
            if (existing == null) {
              byShop[id] = _ShopAgg(
                shopId: id,
                name: 'Loading...',
                orderCount: 1,
                totalSales: o.totalAmount,
              );
            } else {
              byShop[id] = existing.copyWith(
                orderCount: existing.orderCount + 1,
                totalSales: existing.totalSales + o.totalAmount,
              );
            }
          }

          final totalOrders = orders.length;

          return FutureBuilder<List<_ShopAgg>>(
            future: _resolveShopNames(byShop.values.toList()),
            builder: (context, shopSnap) {
              final shops = shopSnap.data ?? byShop.values.toList();
              shops.sort((a, b) => b.totalSales.compareTo(a.totalSales));
              final topShops = shops.take(5).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _GlobalSummaryCard(
                      totalSales: totalSales,
                      totalOrders: totalOrders,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Top Performing Shops',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (topShops.isEmpty)
                      const Text('No shop data available')
                    else
                      ...topShops.map(
                        (s) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: const Icon(Icons.store),
                            ),
                            title: Text(
                              s.name.isNotEmpty ? s.name : s.shopId,
                            ),
                            subtitle: Text(
                              '${s.orderCount} orders',
                            ),
                            trailing: Text(
                              '₹${s.totalSales.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_ShopAgg>> _resolveShopNames(List<_ShopAgg> list) async {
    if (list.isEmpty) return list;

    final firestore = FirebaseFirestore.instance;
    final result = <_ShopAgg>[];

    for (final s in list) {
      String name = s.name;
      if (name == 'Loading...' && s.shopId.isNotEmpty) {
        final doc =
            await firestore.collection('shops').doc(s.shopId).get();
        if (doc.exists && doc.data() != null) {
          final shop = ShopModel.fromMap(
            doc.data() as Map<String, dynamic>,
          );
          name = shop.name.isNotEmpty ? shop.name : shop.shopId;
        }
      }
      result.add(s.copyWith(name: name));
    }
    return result;
  }
}

class _GlobalSummaryCard extends StatelessWidget {
  const _GlobalSummaryCard({
    required this.totalSales,
    required this.totalOrders,
  });

  final double totalSales;
  final int totalOrders;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Sales (all shops)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${totalSales.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Orders: $totalOrders',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopAgg {
  final String shopId;
  final String name;
  final int orderCount;
  final double totalSales;

  const _ShopAgg({
    required this.shopId,
    required this.name,
    required this.orderCount,
    required this.totalSales,
  });

  _ShopAgg copyWith({
    String? shopId,
    String? name,
    int? orderCount,
    double? totalSales,
  }) {
    return _ShopAgg(
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      orderCount: orderCount ?? this.orderCount,
      totalSales: totalSales ?? this.totalSales,
    );
  }
}

