import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_rule_safe_update.dart';
import '../../../core/firestore/firestore_pagination.dart';
import '../../../core/firestore/firestore_stream_cache.dart';
import '../../../data/models/customer_model.dart';
import '../../../core/firestore/firestore_parse.dart';
import '../../../data/models/order_model.dart';

/// Customer Detail Screen - View and edit customer, view order history
/// Admin can edit name and mobile. Deletion is not allowed.
class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;
  final String shopId;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
    required this.shopId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _mobileController = TextEditingController(text: widget.customer.mobile);
    _ordersStream = FirestoreStreamCache.instance.querySnapshots(
      firstPageQuery(
        FirebaseFirestore.instance
            .collection('orders')
            .where('shopId', isEqualTo: widget.shopId)
            .where('customerId', isEqualTo: widget.customer.customerId)
            .orderBy('createdAt', descending: true),
        pageSize: FirestorePageSize.history,
      ),
      key:
          'customer_orders_${widget.shopId}_${widget.customer.customerId}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Mobile number should contain only digits';
    }
    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
      return 'Mobile number should start with 6, 7, 8, or 9';
    }
    return null;
  }

  Future<void> _saveCustomer(BuildContext pageContext) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customer.customerId)
          .update(
            FirestoreRuleSafeUpdate.customer(
              widget.customer,
              changes: {
                'name': _nameController.text.trim(),
                'mobile': _mobileController.text.trim(),
              },
            ),
          );

      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully')),
        );
      }
    } catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Error updating customer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : () => _saveCustomer(context),
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            color: colorScheme.onPrimaryContainer,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                widget.customer.customerId,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: colorScheme.outline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validateMobile,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading orders: ${snapshot.error}'),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final orders = FirestoreParse.parseQueryDocs(
                    docs,
                    OrderModel.tryFromMap,
                  );

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          const Text('No orders for this customer yet'),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order History',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total orders: ${orders.length}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _buildOrderTile(context, order);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, OrderModel order) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          order.orderId.length > 10
              ? order.orderId.substring(0, 10).toUpperCase()
              : order.orderId.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₹${order.totalAmount.toStringAsFixed(2)} • ${order.paymentMethod}',
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.orderStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
