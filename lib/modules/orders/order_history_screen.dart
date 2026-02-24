import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../data/models/order_model.dart';
import '../reports/reports_service.dart';

/// Admin Order History: list shop orders, view details, cancel pending (via CF).
/// Locked orders read-only; no delete.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    super.key,
    this.shopId,
    this.readOnly = false,
  });

  final String? shopId;
  /// If true (Viewer), no cancel action.
  final bool readOnly;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ReportsService _reports = ReportsService();
  String? _shopId;
  bool _loading = true;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _resolveShop();
  }

  Future<void> _resolveShop() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    if (widget.shopId != null && widget.shopId!.isNotEmpty) {
      setState(() {
        _shopId = widget.shopId;
        _loading = false;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final role = (data['role'] as String? ?? '').toString().toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');
        setState(() {
          _shopId = data['shopId'] as String? ?? '';
          _isSuperAdmin = role == 'superadmin';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.readOnly ? 'Order History (View Only)' : 'Order History')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_shopId == null || (_shopId!.isEmpty && !_isSuperAdmin)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History')),
        body: const Center(child: Text('Shop not found')),
      );
    }

    final stream = _isSuperAdmin
        ? _reports.streamAllOrdersSuperAdmin()
        : _reports.streamAllOrdersForShop(shopId: _shopId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'Order History (View Only)' : 'Order History'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                readOnly: widget.readOnly,
                onTap: () => _showOrderDetail(context, order),
                onCancel: order.isPending && !widget.readOnly
                    ? () => _cancelOrder(context, order)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showOrderDetail(BuildContext context, OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _OrderDetailSheet(
        order: order,
        readOnly: widget.readOnly,
        onCancel: order.isPending && !widget.readOnly
            ? () {
                Navigator.pop(context);
                _cancelOrder(context, order);
              }
            : null,
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
          'Cancel order ${order.orderId.substring(0, 8).toUpperCase()}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('cancelOrder');
      await callable.call(<String, dynamic>{
        'orderId': order.orderId,
        'shopId': order.shopId,
        'reason': 'Cancelled from Admin Order History',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.readOnly,
    required this.onTap,
    this.onCancel,
  });

  final OrderModel order;
  final bool readOnly;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = order.isCancelled
        ? Colors.red
        : order.isPending
            ? Colors.orange
            : colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderId.length > 8
                          ? order.orderId.substring(0, 8).toUpperCase()
                          : order.orderId.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 8),
              Text(
                '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${order.totalAmount.toStringAsFixed(2)} • ${order.paymentMethod}',
                style: theme.textTheme.bodyMedium,
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel order'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({
    required this.order,
    required this.readOnly,
    this.onCancel,
  });

  final OrderModel order;
  final bool readOnly;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Order ${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId.toUpperCase()}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text('Status: ${order.orderStatus.toUpperCase()}'),
              Text('Payment: ${order.paymentMethod} • ${order.paymentStatus}'),
              Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
              if (order.customerName.isNotEmpty) Text('Customer: ${order.customerName}'),
              if (order.employeeName.isNotEmpty) Text('Employee: ${order.employeeName}'),
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      final qty = (item['quantityOrWeight'] as num?)?.toDouble() ?? 0;
                      final total = (item['totalPrice'] as num?)?.toDouble() ?? 0;
                      final name = item['productName'] as String? ?? 'Product';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('$name × ${qty.toStringAsFixed(2)}'),
                            ),
                            Text('₹${total.toStringAsFixed(2)}'),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => onCancel!(),
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
        );
      },
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
