import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';

/// Inventory Adjustment Screen
/// Admin selects a product, adjustment amount, and reason,
/// then calls the adjustStock Cloud Function.
class InventoryAdjustmentScreen extends StatefulWidget {
  const InventoryAdjustmentScreen({super.key});

  @override
  State<InventoryAdjustmentScreen> createState() =>
      _InventoryAdjustmentScreenState();
}

class _InventoryAdjustmentScreenState extends State<InventoryAdjustmentScreen> {
  String? _shopId;
  bool _isLoadingUser = true;
  String _searchQuery = '';

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
        final userData =
            UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        setState(() {
          _shopId = userData.shopId;
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _showAdjustmentDialog(ProductModel product) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    bool isIncrease = true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adjust Stock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current stock: ${product.stock.toStringAsFixed(2)} ${product.measurementType}',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Increase'),
                        selected: isIncrease,
                        onSelected: (selected) {
                          if (selected) {
                            setStateDialog(() {
                              isIncrease = true;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Decrease'),
                        selected: !isIncrease,
                        onSelected: (selected) {
                          if (selected) {
                            setStateDialog(() {
                              isIncrease = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Adjustment amount (${product.measurementType})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                    final amount = double.tryParse(amountController.text);
                    final reason = reasonController.text.trim();
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reason is required'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop<Map<String, dynamic>>(context, {
                      'amount': amount,
                      'isIncrease': isIncrease,
                      'reason': reason,
                    });
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    final amount = result['amount'] as double;
    final isIncreaseResult = result['isIncrease'] as bool;
    final reason = result['reason'] as String;

    await _callAdjustStock(product, amount, isIncreaseResult, reason);
  }

  Future<void> _callAdjustStock(
    ProductModel product,
    double amount,
    bool isIncrease,
    String reason,
  ) async {
    if (_shopId == null || _shopId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop ID not found')),
      );
      return;
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('adjustStock');
      final adjustment = isIncrease ? amount : -amount;

      await callable.call<Map<String, dynamic>>({
        'productId': product.productId,
        'shopId': _shopId,
        'adjustment': adjustment,
        'reason': reason,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock ${isIncrease ? 'increased' : 'decreased'} by '
            '${amount.toStringAsFixed(2)} ${product.measurementType}',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to adjust stock: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adjusting stock: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory Adjustment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shopId == null || _shopId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inventory Adjustment')),
        body: const Center(child: Text('Shop not found')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Adjustment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
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
                          color: colorScheme.error,
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
                          color: colorScheme.outline,
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
                    .map(
                      (doc) => ProductModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                List<ProductModel> filtered = allProducts;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = allProducts
                      .where(
                        (p) =>
                            p.name.toLowerCase().contains(q) ||
                            p.productId.toLowerCase().contains(q),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No products match your search',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final isOutOfStock = product.stock <= 0;
                    final isLowStock =
                        product.stock > 0 && product.stock <= 10;

                    Color stockColor;
                    if (isOutOfStock) {
                      stockColor = colorScheme.error;
                    } else if (isLowStock) {
                      stockColor = colorScheme.errorContainer;
                    } else {
                      stockColor = colorScheme.primary;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: stockColor.withOpacity(0.1),
                          child: Icon(
                            Icons.inventory_2,
                            color: stockColor,
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Stock: ${product.stock.toStringAsFixed(2)} ${product.measurementType}',
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Price: ₹${product.price.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        trailing: FilledButton(
                          onPressed: () => _showAdjustmentDialog(product),
                          child: const Text('Adjust'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

