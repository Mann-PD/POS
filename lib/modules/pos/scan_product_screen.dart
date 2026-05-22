import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/models/product_model.dart';
import 'controllers/cart_controller.dart';
import 'package:get/get.dart';

/// Scan product barcode/QR and add to cart.
/// Read-only: looks up product in current shop and delegates to provided callback.
class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({
    super.key,
    required this.shopId,
    required this.onProductScanned,
  });

  final String shopId;
  final void Function(ProductModel product) onProductScanned;

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  bool _isProcessing = false;
  String? _lastCode;

  Future<ProductModel?> _findProduct(String code) async {
    final db = FirebaseFirestore.instance;

    // Try by explicit barcode field (future-proof)
    Query<Map<String, dynamic>> base =
        db.collection('products').where('shopId', isEqualTo: widget.shopId);

    // 1. barcode == code
    var snap = await base.where('barcode', isEqualTo: code).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return ProductModel.tryFromQueryDocument(snap.docs.first);
    }

    // 2. productId == code
    snap = await base.where('productId', isEqualTo: code).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return ProductModel.tryFromQueryDocument(snap.docs.first);
    }

    // 3. name == code
    snap = await base.where('name', isEqualTo: code).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return ProductModel.tryFromQueryDocument(snap.docs.first);
    }

    return null;
  }

  Future<void> _handleBarcode(BuildContext context, String? rawValue) async {
    if (rawValue == null || rawValue.isEmpty) return;
    // Debounce same code repeatedly
    if (_isProcessing || _lastCode == rawValue) return;

    setState(() {
      _isProcessing = true;
      _lastCode = rawValue;
    });

    try {
      final product = await _findProduct(rawValue);
      if (product == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No product found for code: $rawValue'),
            backgroundColor: Colors.red,
          ),
        );
        if (!context.mounted) return;
        setState(() => _isProcessing = false);
        return;
      }

      // Basic validation: status + stock, then add directly with quantity 1
      if (product.stock <= 0 || product.status != 'Active') {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product is not available'),
            backgroundColor: Colors.red,
          ),
        );
        if (!context.mounted) return;
        setState(() => _isProcessing = false);
        return;
      }

      // Use cart controller directly when adding from scan (quantity 1)
      final cart = Get.find<CartController>();
      cart.addItem(product, 1);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart (scan)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );

      widget.onProductScanned(product);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (context.mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final code = barcodes.first.rawValue;
                _handleBarcode(context, code);
              },
            ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Looking up product...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

