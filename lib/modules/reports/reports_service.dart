import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/order_model.dart';
import '../../data/models/expense_model.dart';

/// Role-scoped read-only reports. Uses locked orders only; no data modification.
class ReportsService {
  static const String _ordersLocked = 'locked';
  static const String _ordersPending = 'pending';
  static const String _ordersCancelled = 'cancelled';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of completed (locked) orders for reports.
  /// [shopId] null = all shops (SuperAdmin); [employeeId] non-null = filter to that employee (Employee role).
  Stream<List<OrderModel>> streamLockedOrders({
    String? shopId,
    String? employeeId,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('orders')
        .where('orderStatus', isEqualTo: _ordersLocked);

    if (shopId != null && shopId.isNotEmpty) {
      q = q.where('shopId', isEqualTo: shopId);
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      q = q.where('employeeId', isEqualTo: employeeId);
    }
    q = q.orderBy('createdAt', descending: true);

    return q.snapshots().map((snap) =>
        snap.docs.map((d) => OrderModel.fromMap(d.data())).toList());
  }

  /// One-time fetch for date range (for period reports).
  Future<List<OrderModel>> getLockedOrdersInRange({
    required DateTime start,
    required DateTime end,
    String? shopId,
    String? employeeId,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('orders')
        .where('orderStatus', isEqualTo: _ordersLocked)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    if (shopId != null && shopId.isNotEmpty) {
      q = q.where('shopId', isEqualTo: shopId);
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      q = q.where('employeeId', isEqualTo: employeeId);
    }
    q = q.orderBy('createdAt', descending: true);

    final snap = await q.get();
    return snap.docs.map((d) => OrderModel.fromMap(d.data())).toList();
  }

  /// Stream all orders for order history (pending + locked + cancelled).
  Stream<List<OrderModel>> streamAllOrdersForShop({
    required String shopId,
  }) {
    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromMap(d.data())).toList());
  }

  /// Stream all orders for SuperAdmin (cross-shop). No shopId filter.
  Stream<List<OrderModel>> streamAllOrdersSuperAdmin() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromMap(d.data())).toList());
  }

  /// Stream expenses for a shop. Pass empty shopId for SuperAdmin (all) - need to fetch all.
  Stream<List<ExpenseModel>> streamExpenses({String? shopId}) {
    if (shopId != null && shopId.isNotEmpty) {
      return _db
          .collection('expenses')
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ExpenseModel.fromMap(d.data()))
              .toList());
    }
    // SuperAdmin: all expenses (no shopId filter)
    return _db
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ExpenseModel.fromMap(d.data())).toList());
  }

  /// Fetch order items for an order (for product-wise breakdown).
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final snap = await _db
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Fetch expenses in date range for summary.
  Future<List<ExpenseModel>> getExpensesInRange({
    required DateTime start,
    required DateTime end,
    String? shopId,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('expenses')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));

    if (shopId != null && shopId.isNotEmpty) {
      q = q.where('shopId', isEqualTo: shopId);
    }
    q = q.orderBy('createdAt', descending: true);

    final snap = await q.get();
    return snap.docs.map((d) => ExpenseModel.fromMap(d.data())).toList();
  }

  static bool isPending(String orderStatus) =>
      orderStatus.toLowerCase() == _ordersPending;
  static bool isLocked(String orderStatus) =>
      orderStatus.toLowerCase() == _ordersLocked;
  static bool isCancelled(String orderStatus) =>
      orderStatus.toLowerCase() == _ordersCancelled;
}
