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
      orderItemId: map['orderItemId'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantityOrWeight: (map['quantityOrWeight'] as num?)?.toDouble() ?? 0,
      priceSnapshot: (map['priceSnapshot'] as num?)?.toDouble() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
    );
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
