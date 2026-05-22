import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_parse.dart';

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

  static String _normalizeStatus(dynamic value) {
    final s = FirestoreParse.stringField(value, fallback: 'Active');
    if (s.isEmpty) return 'Active';
    final lower = s.toLowerCase().trim();
    if (lower == 'active') return 'Active';
    if (lower == 'inactive') return 'Inactive';
    return s;
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: FirestoreParse.stringField(map['categoryId']),
      shopId: FirestoreParse.stringField(map['shopId']),
      name: FirestoreParse.stringField(map['name']),
      status: _normalizeStatus(map['status']),
      createdAt: FirestoreParse.dateTimeField(map['createdAt']),
    );
  }

  static CategoryModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final category = CategoryModel.fromMap(map);
    if (category.categoryId.isEmpty) return null;
    return category;
  }

  static CategoryModel? tryFromQueryDocument(QueryDocumentSnapshot doc) {
    return FirestoreParse.tryParseQuery(
      doc,
      CategoryModel.fromMap,
      validate: (c) => c.categoryId.isNotEmpty,
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
