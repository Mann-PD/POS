import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_parse.dart';

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
      logId: FirestoreParse.stringField(map['logId']),
      userId: FirestoreParse.stringField(map['userId']),
      role: FirestoreParse.stringField(map['role']),
      shopId: FirestoreParse.stringField(map['shopId']),
      action: FirestoreParse.stringField(map['action']),
      entityType: FirestoreParse.stringField(map['entityType']),
      entityId: FirestoreParse.stringField(map['entityId']),
      details: FirestoreParse.mapField(map['details']),
      timestamp: FirestoreParse.dateTimeField(map['timestamp']),
    );
  }

  static AuditLogModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final log = AuditLogModel.fromMap(map);
    if (log.logId.isEmpty && log.action.isEmpty) return null;
    return log;
  }

  static AuditLogModel? tryFromQueryDocument(QueryDocumentSnapshot doc) {
    return FirestoreParse.tryParseQuery(
      doc,
      AuditLogModel.fromMap,
      validate: (l) => l.logId.isNotEmpty || l.action.isNotEmpty,
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
