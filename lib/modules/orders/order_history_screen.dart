import 'package:flutter/material.dart';

/// Order History Screen - View all orders (Admin read-only)
/// This is a placeholder screen - full implementation pending
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64),
            SizedBox(height: 16),
            Text('Order History'),
            SizedBox(height: 8),
            Text('Full implementation pending'),
          ],
        ),
      ),
    );
  }
}
