import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_parse.dart';

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
      logId: FirestoreParse.stringField(map['logId']),
      productId: FirestoreParse.stringField(map['productId']),
      shopId: FirestoreParse.stringField(map['shopId']),
      change: FirestoreParse.doubleField(map['change']),
      reason: FirestoreParse.stringField(map['reason']),
      createdAt: FirestoreParse.dateTimeField(map['createdAt']),
    );
  }

  static InventoryLogModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final log = InventoryLogModel.fromMap(map);
    if (log.logId.isEmpty && log.productId.isEmpty) return null;
    return log;
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
