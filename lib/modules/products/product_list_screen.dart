import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import 'controllers/product_ui_controller.dart';
import 'product_form_screen.dart';

/// Product List Screen - Admin view of all products
/// Allows viewing, adding, editing, and disabling products
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductUiController _uiController = Get.put(ProductUiController());
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

  Future<void> _toggleProductStatus(ProductModel product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.productId)
          .update({
        'status': product.status == 'active' ? 'inactive' : 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product ${product.status == 'active' ? 'deactivated' : 'activated'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductFormScreen(),
                ),
              );
            },
            tooltip: 'Add Product',
          ),
        ],
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
                    _buildFilterChip('active', 'Active'),
                    _buildFilterChip('inactive', 'Inactive'),
                    _buildFilterChip('low-stock', 'Low Stock'),
                  ],
                ),
              )),

          const SizedBox(height: 8),

          // Products list
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
                        Text('Error loading products: ${snapshot.error}'),
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
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first product',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
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

                  // Filter by status
                  if (_uiController.selectedFilter.value == 'active') {
                    filteredProducts = filteredProducts
                        .where((product) => product.status == 'active')
                        .toList();
                  } else if (_uiController.selectedFilter.value == 'inactive') {
                    filteredProducts = filteredProducts
                        .where((product) => product.status == 'inactive')
                        .toList();
                  } else if (_uiController.selectedFilter.value == 'low-stock') {
                    filteredProducts = filteredProducts
                        .where((product) => product.stock <= 10)
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
                      return _buildProductCard(context, product);
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

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = product.stock <= 10;
    final isDisabled = product.status == 'inactive';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDisabled
              ? colorScheme.errorContainer
              : isLowStock
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
          child: Icon(
            isDisabled
                ? Icons.block
                : isLowStock
                    ? Icons.warning
                    : Icons.inventory_2,
            color: isDisabled
                ? colorScheme.onErrorContainer
                : isLowStock
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            decoration: isDisabled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Price: ₹${product.price.toStringAsFixed(2)}'),
            Text('Stock: ${product.stock.toStringAsFixed(2)} ${product.measurementType}'),
            if (isLowStock && !isDisabled)
              Text(
                'Low Stock!',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductFormScreen(product: product),
                ),
              );
            } else if (value == 'toggle') {
              _toggleProductStatus(product);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    product.status == 'active' ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(product.status == 'active' ? 'Disable' : 'Enable'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
