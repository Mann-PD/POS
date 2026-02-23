import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'controllers/cart_controller.dart';
import 'receipt_screen.dart';
import '../../data/models/user_model.dart';

/// Payment Selection Screen - Select payment method and complete order
class PaymentScreen extends StatefulWidget {
  final String customerName;
  final String customerMobile;

  const PaymentScreen({
    super.key,
    required this.customerName,
    required this.customerMobile,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  String? _shopId;
  String? _userId;

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
          Navigator.of(context).pushReplacementNamed('/login');
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
          _userId = userData.userId;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  Future<void> _confirmOrder() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_shopId == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to process order. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cartController = Get.find<CartController>();
      
      if (cartController.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cart is empty'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Step 1: Create or get customer
      final customerId = await _createOrGetCustomer();

      // Step 2: Save total amount before clearing cart
      final totalAmount = cartController.totalAmount;
      final cartItems = List.from(cartController.items);

      // Step 3: Create order document
      final orderId = FirebaseFirestore.instance
          .collection('orders')
          .doc()
          .id;

      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId);

      // Step 4: Create order items
      final orderItemsRef = FirebaseFirestore.instance
          .collection('order_items');

      final batch = FirebaseFirestore.instance.batch();

      // Create order document (paymentStatus must be 'Success' for confirmOrder and Firestore rules)
      batch.set(orderRef, {
        'orderId': orderId,
        'shopId': _shopId,
        'customerId': customerId,
        'employeeId': _userId,
        'totalAmount': totalAmount,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': 'Success',
        'orderStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create order items
      for (final item in cartItems) {
        final itemId = orderItemsRef.doc().id;
        batch.set(orderItemsRef.doc(itemId), {
          'orderItemId': itemId,
          'orderId': orderId,
          'productId': item.product.productId,
          'quantityOrWeight': item.quantityOrWeight,
          'priceSnapshot': item.priceSnapshot,
          'totalPrice': item.totalPrice,
        });
      }

      await batch.commit();

      // Step 5: Call Cloud Function to confirm order
      final functions = FirebaseFunctions.instance;
      final confirmOrderFunction = functions.httpsCallable('confirmOrder');

      final result = await confirmOrderFunction.call({
        'orderId': orderId,
        'shopId': _shopId,
      });

      if (result.data['success'] == true) {
        // Order confirmed successfully
        if (mounted) {
          // Clear cart after successful order
          cartController.clear();
          
          // Navigate to receipt screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(
                orderId: orderId,
                customerName: widget.customerName,
                customerMobile: widget.customerMobile,
                totalAmount: totalAmount,
                paymentMethod: _selectedPaymentMethod!,
              ),
            ),
          );
        }
      } else {
        throw Exception(result.data['error'] ?? 'Failed to confirm order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing order: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String> _createOrGetCustomer() async {
    // Check if customer exists by mobile number
    final existingCustomers = await FirebaseFirestore.instance
        .collection('customers')
        .where('shopId', isEqualTo: _shopId)
        .where('mobile', isEqualTo: widget.customerMobile)
        .limit(1)
        .get();

    if (existingCustomers.docs.isNotEmpty) {
      return existingCustomers.docs.first.id;
    }

    // Create new customer
    final customerRef = FirebaseFirestore.instance
        .collection('customers')
        .doc();

    await customerRef.set({
      'customerId': customerRef.id,
      'shopId': _shopId,
      'name': widget.customerName,
      'mobile': widget.customerMobile,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return customerRef.id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer info summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.customerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.customerMobile,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Payment methods
                    Text(
                      'Select Payment Method',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethodCard(
                      icon: Icons.money,
                      title: 'Cash',
                      subtitle: 'Cash payment',
                      isSelected: _selectedPaymentMethod == 'cash',
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = 'cash';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethodCard(
                      icon: Icons.account_balance_wallet,
                      title: 'UPI / Online Payment',
                      subtitle: 'UPI, PhonePe, Google Pay, etc.',
                      isSelected: _selectedPaymentMethod == 'upi',
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = 'upi';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethodCard(
                      icon: Icons.credit_card,
                      title: 'Card',
                      subtitle: 'Debit or Credit Card',
                      isSelected: _selectedPaymentMethod == 'card',
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = 'card';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Order summary and confirm button
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final cartController = Get.find<CartController>();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${cartController.totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _confirmOrder,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Confirm Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
