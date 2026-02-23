import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String categoryId;
  final String shopId;
  final String name;
  final String status; // Active / Inactive
  final DateTime createdAt;

  const CategoryModel({
    required this.categoryId,
    required this.shopId,
    required this.name,
    required this.status,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['categoryId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'shopId': shopId,
      'name': name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
