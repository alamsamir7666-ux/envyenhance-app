import '../models/order.dart';
import 'api_client.dart';

class OrdersRepository {
  OrdersRepository(this._client);
  final ApiClient _client;

  Future<List<Order>> myOrders() async {
    final res = await _client.get<List<dynamic>>('/orders');
    return (res.data ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> getById(int id) async {
    final res = await _client.get<Map<String, dynamic>>('/orders/$id');
    return Order.fromJson(res.data!);
  }

  Future<Order> trackByTrackingId(String trackingId) async {
    final res =
        await _client.get<Map<String, dynamic>>('/orders/track/$trackingId');
    return Order.fromJson(res.data!);
  }

  /// Places an order from the user's current server-side cart.
  /// [paymentMethod] is one of "cod" | "bkash" | "nagad".
  /// [senderNumber] is required for bkash/nagad.
  Future<Order> placeOrder({
    required String paymentMethod,
    String? transactionId,
    String? senderNumber,
    required ShippingAddress shippingAddress,
    String? couponCode,
    int? loyaltyPointsToRedeem,
    bool giftWrap = false,
    String? giftMessage,
  }) async {
    final res = await _client.post<Map<String, dynamic>>('/orders', data: {
      'paymentMethod': paymentMethod,
      if (transactionId != null) 'transactionId': transactionId,
      if (senderNumber != null) 'senderNumber': senderNumber,
      'shippingAddress': shippingAddress.toJson(),
      if (couponCode != null) 'couponCode': couponCode,
      if (loyaltyPointsToRedeem != null)
        'loyaltyPointsToRedeem': loyaltyPointsToRedeem,
      'giftWrap': giftWrap.toString(),
      if (giftMessage != null) 'giftMessage': giftMessage,
    });
    return Order.fromJson(res.data!);
  }

  Future<Order> cancelOrder(int id, {String? reason}) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/orders/$id/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return Order.fromJson(res.data!);
  }
}
