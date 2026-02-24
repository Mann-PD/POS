import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String shopId;
  final String name;
  final String categoryId; // link to categories collection
  final double price; // must be > 0
  final String
  measurementType; // kg, gm, piece, box — immutable after first sale
  final double stock; // must be >= 0
  final String status; // Canonical: Active, Inactive
  final DateTime createdAt; // immutable

  const ProductModel({
    required this.productId,
    required this.shopId,
    required this.name,
    this.categoryId = '',
    required this.price,
    required this.measurementType,
    required this.stock,
    required this.status,
    required this.createdAt,
  });

  /// Whether this product can be sold
  bool get isActive => status == 'Active';

  /// Whether this product is sold by weight (kg/gm)
  bool get isWeightBased => measurementType == 'kg' || measurementType == 'gm';

  /// Whether this product is available for sale (active + in stock)
  bool get isAvailable => isActive && stock > 0;

  /// Canonical product status: Active, Inactive (matches backend)
  static String _normalizeProductStatus(String? value) {
    if (value == null || value.isEmpty) return 'Active';
    final lower = value.toLowerCase().trim();
    if (lower == 'active') return 'Active';
    if (lower == 'inactive' || lower == 'disabled') return 'Inactive';
    return value;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId: map['productId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      measurementType: map['measurementType'] as String? ?? 'piece',
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      status: _normalizeProductStatus(map['status'] as String?),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'shopId': shopId,
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'measurementType': measurementType,
      'stock': stock,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ProductModel copyWith({
    String? productId,
    String? shopId,
    String? name,
    String? categoryId,
    double? price,
    String? measurementType,
    double? stock,
    String? status,
    DateTime? createdAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      measurementType: measurementType ?? this.measurementType,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
