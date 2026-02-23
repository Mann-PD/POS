import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/product_model.dart';
import 'pos_home_screen.dart';

/// Order Success & Receipt Screen - Display order confirmation and receipt
class ReceiptScreen extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String customerMobile;
  final double totalAmount;
  final String paymentMethod;

  const ReceiptScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerMobile,
    required this.totalAmount,
    required this.paymentMethod,
  });

  String _getPaymentMethodLabel() {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI / Online Payment';
      case 'card':
        return 'Card';
      default:
        return paymentMethod;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Success icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 48,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Order Placed Successfully!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order ID: $orderId',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Receipt card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order items
                            Text(
                              'Order Items',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: () async {
                                final itemsSnapshot = await FirebaseFirestore.instance
                                    .collection('order_items')
                                    .where('orderId', isEqualTo: orderId)
                                    .get();

                                final items = <Map<String, dynamic>>[];
                                
                                for (final itemDoc in itemsSnapshot.docs) {
                                  final itemData = itemDoc.data();
                                  final productDoc = await FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(itemData['productId'] as String)
                                      .get();
                                  
                                  if (productDoc.exists) {
                                    final product = ProductModel.fromMap(
                                      productDoc.data() as Map<String, dynamic>,
                                    );
                                    items.add({
                                      'product': product,
                                      'quantity': itemData['quantityOrWeight'] as double,
                                      'price': itemData['priceSnapshot'] as double,
                                      'total': itemData['totalPrice'] as double,
                                    });
                                  }
                                }
                                
                                return items;
                              }(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No items found'),
                                  );
                                }

                                final orderItems = snapshot.data!;

                                return Column(
                                  children: orderItems.map((item) {
                                    final product = item['product'] as ProductModel;
                                    final quantity = item['quantity'] as double;
                                    final total = item['total'] as double;
                                    final price = item['price'] as double;
                                    final isWeightBased = product.measurementType
                                        .toLowerCase() == 'kg' ||
                                        product.measurementType.toLowerCase() == 'gm';

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: theme.textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${quantity.toStringAsFixed(isWeightBased ? 2 : 0)} ${product.measurementType.toLowerCase()} × ₹${price.toStringAsFixed(2)}',
                                                  style: theme.textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                    color: colorScheme
                                                        .outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹${total.toStringAsFixed(2)}',
                                            style: theme.textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const Divider(height: 32),
                            // Customer info
                            _ReceiptInfoRow(
                              label: 'Customer',
                              value: customerName,
                            ),
                            const SizedBox(height: 8),
                            _ReceiptInfoRow(
                              label: 'Mobile',
                              value: customerMobile,
                            ),
                            const SizedBox(height: 8),
                            _ReceiptInfoRow(
                              label: 'Payment Method',
                              value: _getPaymentMethodLabel(),
                            ),
                            const Divider(height: 32),
                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Print/share options
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement print functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Print functionality coming soon'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Print'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement share functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Share functionality coming soon'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // New order button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const PosHomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('New Order'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
