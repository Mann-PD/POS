import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_parse.dart';

class ShopModel {
  final String shopId;
  final String name;
  final String status; // Active / Inactive
  final DateTime createdAt;

  const ShopModel({
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

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      shopId: FirestoreParse.stringField(map['shopId']),
      name: FirestoreParse.stringField(map['name']),
      status: _normalizeStatus(map['status']),
      createdAt: FirestoreParse.dateTimeField(map['createdAt']),
    );
  }

  static ShopModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final shop = ShopModel.fromMap(map);
    if (shop.shopId.isEmpty) return null;
    return shop;
  }

  static ShopModel? tryFromDocument(DocumentSnapshot doc) {
    return FirestoreParse.tryParse(
      doc,
      ShopModel.fromMap,
      validate: (s) => s.shopId.isNotEmpty,
    );
  }

  static ShopModel? tryFromQueryDocument(QueryDocumentSnapshot doc) {
    return FirestoreParse.tryParseQuery(
      doc,
      ShopModel.fromMap,
      validate: (s) => s.shopId.isNotEmpty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'name': name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
