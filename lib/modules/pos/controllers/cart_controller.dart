import 'package:get/get.dart';
import 'package:pos_system/data/models/product_model.dart';

/// Cart item model
class CartItem {
  final ProductModel product;
  final double quantityOrWeight;
  final double priceSnapshot;

  CartItem({
    required this.product,
    required this.quantityOrWeight,
    required this.priceSnapshot,
  });

  double get totalPrice => quantityOrWeight * priceSnapshot;
}

/// Cart controller for managing POS cart UI state
class CartController extends GetxController {
  final RxList<CartItem> _items = <CartItem>[].obs;

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  bool get isEmpty => _items.isEmpty;

  /// Add item to cart
  void addItem(ProductModel product, double quantityOrWeight) {
    // Check if product already exists in cart
    final existingIndex = _items.indexWhere(
      (item) => item.product.productId == product.productId,
    );

    if (existingIndex >= 0) {
      // Update existing item quantity
      final existingItem = _items[existingIndex];
      final newQuantity = existingItem.quantityOrWeight + quantityOrWeight;
      
      // Validate stock
      if (newQuantity > product.stock) {
        throw Exception(
          'Insufficient stock. Available: ${product.stock}, Requested: $newQuantity',
        );
      }

      // Update item by removing and re-adding to ensure reactivity
      _items.removeAt(existingIndex);
      _items.insert(existingIndex, CartItem(
        product: product,
        quantityOrWeight: newQuantity,
        priceSnapshot: product.price,
      ));
    } else {
      // Add new item
      _items.add(
        CartItem(
          product: product,
          quantityOrWeight: quantityOrWeight,
          priceSnapshot: product.price,
        ),
      );
    }
  }

  /// Update item quantity
  void updateQuantity(String productId, double newQuantity) {
    final index = _items.indexWhere(
      (item) => item.product.productId == productId,
    );

    if (index < 0) return;

    final item = _items[index];
    
    // Validate stock
    if (newQuantity > item.product.stock) {
      throw Exception(
        'Insufficient stock. Available: ${item.product.stock}, Requested: $newQuantity',
      );
    }

    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    // Update item by removing and re-adding to ensure reactivity
    _items.removeAt(index);
    _items.insert(index, CartItem(
      product: item.product,
      quantityOrWeight: newQuantity,
      priceSnapshot: item.priceSnapshot,
    ));
  }

  /// Remove item from cart
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.productId == productId);
  }

  /// Clear cart
  void clear() {
    _items.clear();
  }

  /// Get cart item by product ID
  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere(
        (item) => item.product.productId == productId,
      );
    } catch (e) {
      return null;
    }
  }
}
