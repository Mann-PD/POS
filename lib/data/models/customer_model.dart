import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String customerId;
  final String shopId;
  final String name;
  final String mobile;
  final DateTime createdAt; // immutable

  const CustomerModel({
    required this.customerId,
    required this.shopId,
    required this.name,
    required this.mobile,
    required this.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      customerId: map['customerId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      mobile: map['mobile'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'shopId': shopId,
      'name': name,
      'mobile': mobile,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
