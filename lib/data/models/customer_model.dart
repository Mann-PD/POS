import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_parse.dart';

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
      customerId: FirestoreParse.stringField(map['customerId']),
      shopId: FirestoreParse.stringField(map['shopId']),
      name: FirestoreParse.stringField(map['name']),
      mobile: FirestoreParse.stringField(map['mobile']),
      createdAt: FirestoreParse.dateTimeField(map['createdAt']),
    );
  }

  static CustomerModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final customer = CustomerModel.fromMap(map);
    if (customer.customerId.isEmpty) return null;
    return customer;
  }

  static CustomerModel? tryFromQueryDocument(QueryDocumentSnapshot doc) {
    return FirestoreParse.tryParseQuery(
      doc,
      CustomerModel.fromMap,
      validate: (c) => c.customerId.isNotEmpty,
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
