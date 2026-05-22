import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_parse.dart';

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
      expenseId: FirestoreParse.stringField(map['expenseId']),
      shopId: FirestoreParse.stringField(map['shopId']),
      amount: FirestoreParse.doubleField(map['amount']),
      description: FirestoreParse.stringField(map['description']),
      category: FirestoreParse.stringField(map['category'], fallback: 'Other'),
      createdBy: FirestoreParse.stringField(map['createdBy']),
      createdAt: FirestoreParse.dateTimeField(map['createdAt']),
    );
  }

  static ExpenseModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final expense = ExpenseModel.fromMap(map);
    if (expense.expenseId.isEmpty && expense.shopId.isEmpty) return null;
    return expense;
  }

  static ExpenseModel? tryFromQueryDocument(QueryDocumentSnapshot doc) {
    return FirestoreParse.tryParseQuery(
      doc,
      ExpenseModel.fromMap,
      validate: (e) => e.shopId.isNotEmpty,
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
