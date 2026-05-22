import '../../core/firestore/firestore_parse.dart';

class OrderItemModel {
  final String orderItemId;
  final String orderId;
  final String productId;
  final String productName; // snapshot for receipt display
  final double quantityOrWeight;
  final double priceSnapshot; // price at time of sale (immutable)
  final double totalPrice;

  const OrderItemModel({
    required this.orderItemId,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantityOrWeight,
    required this.priceSnapshot,
    required this.totalPrice,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      orderItemId: FirestoreParse.stringField(map['orderItemId']),
      orderId: FirestoreParse.stringField(map['orderId']),
      productId: FirestoreParse.stringField(map['productId']),
      productName: FirestoreParse.stringField(map['productName']),
      quantityOrWeight: FirestoreParse.doubleField(map['quantityOrWeight']),
      priceSnapshot: FirestoreParse.doubleField(map['priceSnapshot']),
      totalPrice: FirestoreParse.doubleField(map['totalPrice']),
    );
  }

  static OrderItemModel? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final item = OrderItemModel.fromMap(map);
    if (item.orderId.isEmpty) return null;
    return item;
  }

  Map<String, dynamic> toMap() {
    return {
      'orderItemId': orderItemId,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'quantityOrWeight': quantityOrWeight,
      'priceSnapshot': priceSnapshot,
      'totalPrice': totalPrice,
    };
  }
}
