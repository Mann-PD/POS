import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryLogModel {
  final String logId;
  final String productId;
  final String shopId;
  final double change; // positive = stock added, negative = stock deducted
  final String reason; // e.g., "order_confirmed", "manual_adjustment"
  final DateTime createdAt;

  const InventoryLogModel({
    required this.logId,
    required this.productId,
    required this.shopId,
    required this.change,
    required this.reason,
    required this.createdAt,
  });

  factory InventoryLogModel.fromMap(Map<String, dynamic> map) {
    return InventoryLogModel(
      logId: map['logId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      change: (map['change'] as num?)?.toDouble() ?? 0,
      reason: map['reason'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'productId': productId,
      'shopId': shopId,
      'change': change,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
