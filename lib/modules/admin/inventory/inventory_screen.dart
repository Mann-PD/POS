import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/user_model.dart';
import '../../../widgets/firestore_paginated_list.dart';
import '../../../routing/permission_gate.dart';
import '../../../routing/screen_permission.dart';
import 'inventory_controller.dart';

/// Inventory Management Screen - Admin view and management of stock levels
/// Allows viewing inventory and manual stock adjustments
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryController _controller = Get.put(InventoryController());
  String? _shopId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadUserData(context);
    });
  }

  Future<void> _loadUserData(BuildContext pageContext) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (pageContext.mounted) {
          Navigator.of(pageContext).pop();
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = UserModel.tryFromDocument(userDoc);
        if (userData == null) return;
        if (!mounted) return;
        setState(() {
          _shopId = userData.shopId;
          _isLoading = false;
        });
        _controller.setLoading(false);
      }
    } catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _controller.setLoading(false);
    }
  }

  Future<void> _adjustStock(
    BuildContext pageContext,
    ProductModel product,
    double adjustment,
    bool isIncrease,
    String reason,
  ) async {
    if (_shopId == null || _shopId!.isEmpty) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Shop ID not found')),
        );
      }
      return;
    }

    try {
      _controller.setLoading(true);
      final signedAdjustment = isIncrease ? adjustment : -adjustment;

      await FirebaseFunctions.instance.httpsCallable('adjustStock').call({
        'productId': product.productId,
        'shopId': _shopId,
        'adjustment': signedAdjustment,
        'reason': reason,
      });

      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(
            content: Text(
              'Stock ${isIncrease ? 'increased' : 'decreased'} by ${adjustment.toStringAsFixed(2)} ${product.measurementType}',
            ),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Failed to adjust stock (${e.code})',
            ),
          ),
        );
      }
    } catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    } finally {
      _controller.setLoading(false);
    }
  }

  Future<void> _showStockAdjustmentDialog(
    BuildContext pageContext,
    ProductModel product,
    bool isIncrease,
  ) async {
    final adjustmentController = TextEditingController();
    final reasonController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: pageContext,
      builder: (context) => AlertDialog(
        title: Text(
          isIncrease ? 'Increase Stock' : 'Decrease Stock',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product.name}'),
            const SizedBox(height: 8),
            Text(
              'Current Stock: ${product.stock.toStringAsFixed(2)} ${product.measurementType}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adjustmentController,
              decoration: InputDecoration(
                labelText: 'Amount (${product.measurementType})',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  isIncrease ? Icons.add : Icons.remove,
                ),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final adjustment = double.tryParse(adjustmentController.text);
              final reason = reasonController.text.trim();
              if (adjustment != null && adjustment > 0 && reason.isNotEmpty) {
                Navigator.pop(context, {
                  'adjustment': adjustment,
                  'isIncrease': isIncrease,
                  'reason': reason,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid amount and reason'),
                  ),
                );
              }
            },
            child: Text(isIncrease ? 'Increase' : 'Decrease'),
          ),
        ],
      ),
    );

    if (result != null && pageContext.mounted) {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: pageContext,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Stock Adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product: ${product.name}'),
              const SizedBox(height: 8),
              Text(
                'Current Stock: ${product.stock.toStringAsFixed(2)} ${product.measurementType}',
              ),
              const SizedBox(height: 8),
              Text(
                'Adjustment: ${result['isIncrease'] ? '+' : '-'}${result['adjustment'].toStringAsFixed(2)} ${product.measurementType}',
                style: TextStyle(
                  color: result['isIncrease']
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New Stock: ${(result['isIncrease'] ? product.stock + result['adjustment'] : product.stock - result['adjustment']).toStringAsFixed(2)} ${product.measurementType}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirm == true && pageContext.mounted) {
        _adjustStock(
          pageContext,
          product,
          result['adjustment'] as double,
          result['isIncrease'] as bool,
          result['reason'] as String,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: ScreenPermission.inventory,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  if (_controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _controller.clearSearchQuery(),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _controller.setSearchQuery(value),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('Active', 'Active'),
                  _buildFilterChip('Inactive', 'Inactive'),
                  _buildFilterChip('low-stock', 'Low Stock'),
                  _buildFilterChip('out-of-stock', 'Out of Stock'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Obx(
              () => FirestorePaginatedList<ProductModel>(
                cacheKey: 'inventory_products_$_shopId',
                queryBuilder: () => FirebaseFirestore.instance
                    .collection('products')
                    .where('shopId', isEqualTo: _shopId)
                    .orderBy('name'),
                parse: (data, _) => ProductModel.tryFromMap(data),
                itemKey: (p) => p.productId,
                filterItems: (items) {
                  var filtered = items;
                  final q = _controller.searchQuery.value.trim().toLowerCase();
                  if (q.isNotEmpty) {
                    filtered = filtered
                        .where((p) => p.name.toLowerCase().contains(q))
                        .toList();
                  }
                  final f = _controller.selectedFilter.value;
                  if (f == 'Active') {
                    filtered =
                        filtered.where((p) => p.status == 'Active').toList();
                  } else if (f == 'Inactive') {
                    filtered =
                        filtered.where((p) => p.status == 'Inactive').toList();
                  } else if (f == 'low-stock') {
                    filtered = filtered
                        .where((p) => p.stock > 0 && p.stock <= 10)
                        .toList();
                  } else if (f == 'out-of-stock') {
                    filtered =
                        filtered.where((p) => p.stock <= 0).toList();
                  }
                  return filtered;
                },
                emptyBuilder: (context) => const Center(
                  child: Text('No products match your filters'),
                ),
                itemBuilder: (context, product) =>
                    _buildInventoryCard(context, product),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(label),
            selected: _controller.selectedFilter.value == value,
            onSelected: (selected) {
              if (selected) {
                _controller.setSelectedFilter(value);
              }
            },
          ),
        ));
  }

  Widget _buildInventoryCard(BuildContext context, ProductModel product) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 10;
    final isActive = product.status == 'Active';

    Color stockColor;
    IconData stockIcon;

    if (isOutOfStock) {
      stockColor = colorScheme.error;
      stockIcon = Icons.cancel;
    } else if (isLowStock) {
      stockColor = colorScheme.errorContainer;
      stockIcon = Icons.warning_amber_rounded;
    } else {
      stockColor = colorScheme.primary;
      stockIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: stockColor.withValues(alpha: 0.1),
                  child: Icon(stockIcon, color: stockColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              product.status.toUpperCase(),
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: isActive
                                ? colorScheme.primaryContainer
                                : colorScheme.errorContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unit: ${product.measurementType}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.stock.toStringAsFixed(2)} ${product.measurementType}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: stockColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          _showStockAdjustmentDialog(context, product, false),
                      icon: const Icon(Icons.remove, size: 18),
                      label: const Text('Decrease'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          _showStockAdjustmentDialog(context, product, true),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Increase'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
