import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String expenseId;
  final String shopId;
  final double amount; // must be > 0
  final String description;
  final String category; // e.g., Rent, Transport, Wages, Utilities, Other
  final String createdBy; // userId who created it
  final DateTime createdAt; // immutable

  const ExpenseModel({
    required this.expenseId,
    required this.shopId,
    required this.amount,
    required this.description,
    this.category = 'Other',
    this.createdBy = '',
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      expenseId: map['expenseId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'shopId': shopId,
      'amount': amount,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
