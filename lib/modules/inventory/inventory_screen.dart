import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../admin/controllers/inventory_ui_controller.dart';

/// Inventory Management Screen - Admin view of stock levels
/// Allows viewing stock, updating stock, and monitoring low-stock alerts
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryUiController _uiController = Get.put(InventoryUiController());
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
        _uiController.setShopId(_shopId);
        _uiController.setLoading(false);
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
      _uiController.setLoading(false);
    }
  }

  Future<void> _updateStock(ProductModel product, double newStock) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.productId)
          .update({
        'stock': newStock,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e')),
        );
      }
    }
  }

  Future<void> _showUpdateStockDialog(ProductModel product) async {
    final stockController = TextEditingController(
      text: product.stock.toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${product.stock} ${product.measurementType}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'New Stock (${product.measurementType})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              final newStock = double.tryParse(stockController.text);
              if (newStock != null && newStock >= 0) {
                Navigator.pop(context, newStock);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid stock value'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateStock(product, result);
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
                  if (_uiController.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _uiController.clearSearchQuery(),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _uiController.setSearchQuery(value),
            ),
          ),

          // Filter chips
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
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
                  if (_uiController.searchQuery.value.isNotEmpty) {
                    filteredProducts = filteredProducts
                        .where((product) => product.name
                            .toLowerCase()
                            .contains(_uiController.searchQuery.value.toLowerCase()))
                        .toList();
                  }

                  // Filter by stock status
                  if (_uiController.selectedFilter.value == 'low-stock') {
                    filteredProducts = filteredProducts
                        .where((product) => product.stock > 0 && product.stock <= 10)
                        .toList();
                  } else if (_uiController.selectedFilter.value == 'out-of-stock') {
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
            selected: _uiController.selectedFilter.value == value,
            onSelected: (selected) {
              if (selected) {
                _uiController.setSelectedFilter(value);
              }
            },
          ),
        ));
  }

  Widget _buildInventoryCard(BuildContext context, ProductModel product) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOutOfStock = product.stock <= 0;
    final isLowStock = product.stock > 0 && product.stock <= 10;

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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor.withOpacity(0.1),
          child: Icon(stockIcon, color: stockColor),
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Price: ₹${product.price.toStringAsFixed(2)}'),
            Row(
              children: [
                Text(
                  'Stock: ${product.stock.toStringAsFixed(2)} ${product.measurementType}',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLowStock || isOutOfStock) ...[
                  const SizedBox(width: 8),
                  Icon(stockIcon, size: 16, color: stockColor),
                ],
              ],
            ),
          ],
        ),
        trailing: FilledButton.icon(
          onPressed: () => _showUpdateStockDialog(product),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Update'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    );
  }
}
