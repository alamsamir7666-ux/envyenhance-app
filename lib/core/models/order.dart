/// Matches `formatOrder()` in `src/routes/orders.ts`.
class Order {
  Order({
    required this.id,
    required this.trackingId,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.senderNumber,
    this.paidAt,
    required this.orderStatus,
    this.transactionId,
    required this.shippingAddress,
    this.couponCode,
    required this.discountAmount,
    this.cancellationReason,
    required this.giftWrap,
    this.giftMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      trackingId: json['trackingId'] as String? ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? '',
      senderNumber: json['senderNumber'] as String?,
      paidAt: json['paidAt'] as String?,
      orderStatus: json['orderStatus'] as String? ?? 'processing',
      transactionId: json['transactionId'] as String?,
      shippingAddress: ShippingAddress.fromJson(
        (json['shippingAddress'] as Map<String, dynamic>?) ?? const {},
      ),
      couponCode: json['couponCode'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      cancellationReason: json['cancellationReason'] as String?,
      giftWrap: json['giftWrap'] as String? ?? 'false',
      giftMessage: json['giftMessage'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  final int id;
  final String trackingId;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod; // "cod" | "bkash" | "nagad"
  final String paymentStatus; // "pending" | "pending_verification" | "paid"
  final String? senderNumber;
  final String? paidAt;
  final String orderStatus;
  final String? transactionId;
  final ShippingAddress shippingAddress;
  final String? couponCode;
  final double discountAmount;
  final String? cancellationReason;
  final String giftWrap;
  final String? giftMessage;
  final String createdAt;
  final String updatedAt;

  bool get canCancel =>
      orderStatus == 'processing' || orderStatus == 'confirmed';
}

class OrderItem {
  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as int,
      productName: json['productName'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
}

class ShippingAddress {
  ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }

  final String fullName;
  final String phone;
  final String street;
  final String city;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'street': street,
        'city': city,
      };
}
