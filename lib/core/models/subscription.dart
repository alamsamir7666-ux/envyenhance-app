import 'order.dart' show ShippingAddress;

/// Matches the `formatSub()` response shape from `subscriptions.ts`.
class Subscription {
  Subscription({
    required this.id,
    required this.status,
    required this.frequency,
    required this.items,
    required this.shippingAddress,
    required this.totalAmount,
    required this.discountPercent,
    required this.nextOrderDate,
    this.lastOrderDate,
    required this.orderCount,
    required this.paymentMethod,
    this.notes,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      status: json['status'] as String,
      frequency: json['frequency'] as String,
      items: (json['items'] as List)
          .map((e) => SubscriptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingAddress:
          ShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discountPercent: json['discountPercent'] as int,
      nextOrderDate: DateTime.parse(json['nextOrderDate'] as String),
      lastOrderDate: json['lastOrderDate'] != null
          ? DateTime.tryParse(json['lastOrderDate'] as String)
          : null,
      orderCount: json['orderCount'] as int,
      paymentMethod: json['paymentMethod'] as String,
      notes: json['notes'] as String?,
    );
  }

  final int id;
  final String status; // active | paused | cancelled
  final String frequency; // weekly | biweekly | monthly
  final List<SubscriptionItem> items;
  final ShippingAddress shippingAddress;
  final double totalAmount;
  final int discountPercent;
  final DateTime nextOrderDate;
  final DateTime? lastOrderDate;
  final int orderCount;
  final String paymentMethod;
  final String? notes;

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
}

class SubscriptionItem {
  SubscriptionItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String? ?? '',
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  final int productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'quantity': quantity,
        'price': price,
      };
}


