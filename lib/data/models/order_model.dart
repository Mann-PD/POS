import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId; // immutable
  final String shopId;
  final String customerId;
  final String customerName; // snapshot for display
  final String employeeId; // immutable
  final String employeeName; // snapshot for display
  final double totalAmount; // calculated
  final String paymentMethod; // Cash, UPI, Card
  final String paymentStatus; // Success
  final String orderStatus; // pending, locked, cancelled (canonical)
  final DateTime createdAt; // immutable

  const OrderModel({
    required this.orderId,
    required this.shopId,
    required this.customerId,
    this.customerName = '',
    required this.employeeId,
    this.employeeName = '',
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
  });

  /// Whether this order is completed and locked
  bool get isCompleted =>
      orderStatus.toLowerCase() == 'locked';

  /// Whether this order was cancelled
  bool get isCancelled =>
      orderStatus.toLowerCase() == 'cancelled';

  /// Whether this order is still pending (can be cancelled)
  bool get isPending => orderStatus.toLowerCase() == 'pending';

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? '',
      orderStatus: map['orderStatus'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'shopId': shopId,
      'customerId': customerId,
      'customerName': customerName,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
