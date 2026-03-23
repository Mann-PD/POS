import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/order_model.dart';

/// Order Detail Screen
/// Shows order summary, customer and employee, and full item breakdown.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    this.readOnly = false,
    this.onCancel,
  });

  final OrderModel order;
  final bool readOnly;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final date = order.createdAt;
    final dateText =
        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    if (order.isCancelled) {
      statusColor = Colors.red;
    } else if (order.isPending) {
      statusColor = Colors.orange;
    } else {
      statusColor = colorScheme.primary;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderId.length > 8
                              ? order.orderId.substring(0, 8).toUpperCase()
                              : order.orderId.toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.orderStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (order.customerName.isNotEmpty)
                        Text('Customer: ${order.customerName}'),
                      if (order.employeeName.isNotEmpty)
                        Text('Employee: ${order.employeeName}'),
                      Text(
                        'Payment: ${order.paymentMethod} • ${order.paymentStatus}',
                      ),
                      Text(
                        'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadItems(order.orderId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Text('No items');
                  }
                  return Column(
                    children: items.map((item) {
                      final qty =
                          (item['quantityOrWeight'] as num?)?.toDouble() ?? 0;
                      final total =
                          (item['totalPrice'] as num?)?.toDouble() ?? 0;
                      final priceSnapshot =
                          (item['priceSnapshot'] as num?)?.toDouble() ?? 0;
                      final name =
                          item['productName'] as String? ?? 'Product';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qty: ${qty.toStringAsFixed(2)} • Price: ₹${priceSnapshot.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: readOnly ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel this order'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadItems(String orderId) async {
    final itemsSnap = await FirebaseFirestore.instance
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .get();

    final list = <Map<String, dynamic>>[];
    for (final doc in itemsSnap.docs) {
      final data = doc.data();
      final productId = data['productId'] as String?;
      String name = 'Product';
      if (productId != null && productId.isNotEmpty) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        if (productDoc.exists && productDoc.data() != null) {
          name = productDoc.data()!['name'] as String? ?? productId;
        }
      }
      list.add({
        ...data,
        'productName': name,
      });
    }
    return list;
  }
}

