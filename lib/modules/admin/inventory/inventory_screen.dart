import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/user_model.dart';
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

  Future<void> _adjustStock(
    ProductModel product,
    double adjustment,
    bool isIncrease,
  ) async {
    try {
      _controller.setLoading(true);
      final newStock = isIncrease
          ? product.stock + adjustment
          : product.stock - adjustment;

      if (newStock < 0) {
        throw Exception('Stock cannot be negative');
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.productId)
          .update({
        'stock': newStock,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock ${isIncrease ? 'increased' : 'decreased'} by ${adjustment.toStringAsFixed(2)} ${product.measurementType}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    } finally {
      _controller.setLoading(false);
    }
  }

  Future<void> _showStockAdjustmentDialog(
    ProductModel product,
    bool isIncrease,
  ) async {
    final adjustmentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
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
              if (adjustment != null && adjustment > 0) {
                Navigator.pop(context, {
                  'adjustment': adjustment,
                  'isIncrease': isIncrease,
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                  ),
                );
              }
            },
            child: Text(isIncrease ? 'Increase' : 'Decrease'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
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

      if (confirm == true) {
        _adjustStock(
          product,
          result['adjustment'] as double,
          result['isIncrease'] as bool,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    _buildFilterChip('active', 'Active'),
                    _buildFilterChip('inactive', 'Inactive'),
                    _buildFilterChip('low-stock', 'Low Stock'),
                    _buildFilterChip('out-of-stock', 'Out of Stock'),
                  ],
                ),
              )),

          const SizedBox(height: 8),

          // Inventory list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('shopId', isEqualTo: _shopId)
                  .orderBy('name')
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
                        Text('Error loading inventory: ${snapshot.error}'),
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
                          Icons.warehouse_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  );
                }

                final allProducts = snapshot.data!.docs
                    .map((doc) => ProductModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                        ))
                    .toList();

                return Obx(() {
                  var filteredProducts = allProducts;

                  // Filter by search query
                  if (_controller.searchQuery.value.isNotEmpty) {
                    filteredProducts = filteredProducts
                        .where((product) => product.name
                            .toLowerCase()
                            .contains(_controller.searchQuery.value.toLowerCase()))
                        .toList();
                  }

                  // Filter by status
                  if (_controller.selectedFilter.value == 'active') {
                    filteredProducts = filteredProducts
                        .where((product) => product.status == 'active')
                        .toList();
                  } else if (_controller.selectedFilter.value == 'inactive') {
                    filteredProducts = filteredProducts
                        .where((product) => product.status == 'inactive')
                        .toList();
                  } else if (_controller.selectedFilter.value == 'low-stock') {
                    filteredProducts = filteredProducts
                        .where((product) => product.stock > 0 && product.stock <= 10)
                        .toList();
                  } else if (_controller.selectedFilter.value == 'out-of-stock') {
                    filteredProducts = filteredProducts
                        .where((product) => product.stock <= 0)
                        .toList();
                  }

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Text(
                        'No products match your filters',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildInventoryCard(context, product);
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
    final isActive = product.status == 'active';

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
                  backgroundColor: stockColor.withOpacity(0.1),
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
                      onPressed: () => _showStockAdjustmentDialog(product, false),
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
                      onPressed: () => _showStockAdjustmentDialog(product, true),
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
