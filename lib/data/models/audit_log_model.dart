import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String logId;
  final String userId;
  final String role;
  final String shopId;
  final String action; // e.g., login, logout, price_change, order_cancel
  final String entityType; // e.g., user, product, order, expense
  final String entityId;
  final Map<String, dynamic>? details; // optional additional details
  final DateTime timestamp; // immutable

  const AuditLogModel({
    required this.logId,
    required this.userId,
    required this.role,
    required this.shopId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      logId: map['logId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      role: map['role'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      action: map['action'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      details: map['details'] as Map<String, dynamic>?,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'userId': userId,
      'role': role,
      'shopId': shopId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      if (details != null) 'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
