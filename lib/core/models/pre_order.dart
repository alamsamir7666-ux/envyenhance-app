import 'order.dart' show ShippingAddress;

/// Matches the raw `preOrdersTable` row shape (these routes return DB
/// rows directly rather than through a formatter function).
class PreOrder {
  PreOrder({
    required this.id,
    required this.trackingId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.productPrice,
    required this.discountedPrice,
    required this.deliveryCharge,
    required this.shippingAddress,
    required this.paymentMethod,
    this.senderNumber,
    this.transactionId,
    required this.paymentStatus,
    required this.status,
    this.cancellationReason,
    required this.createdAt,
  });

  factory PreOrder.fromJson(Map<String, dynamic> json) {
    return PreOrder(
      id: json['id'] as int,
      trackingId: json['trackingId'] as String,
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String? ?? '',
      quantity: json['quantity'] as int,
      productPrice: double.parse(json['productPrice'].toString()),
      discountedPrice: double.parse(json['discountedPrice'].toString()),
      deliveryCharge: double.parse(json['deliveryCharge'].toString()),
      shippingAddress:
          ShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>),
      paymentMethod: json['paymentMethod'] as String,
      senderNumber: json['senderNumber'] as String?,
      transactionId: json['transactionId'] as String?,
      paymentStatus: json['paymentStatus'] as String,
      status: json['status'] as String,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int id;
  final String trackingId;
  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double productPrice;
  final double discountedPrice;
  final double deliveryCharge;
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final String? senderNumber;
  final String? transactionId;
  final String paymentStatus;
  final String status; // pending | shipped | delivered | cancelled
  final String? cancellationReason;
  final DateTime createdAt;

  double get total => discountedPrice * quantity + deliveryCharge;
}
