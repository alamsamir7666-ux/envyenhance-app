import '../models/order.dart';
import '../models/pre_order.dart';
import 'api_client.dart';

class PreOrdersRepository {
  PreOrdersRepository(this._client);
  final ApiClient _client;

  /// Places a pre-order for a product with `productStatus: "pre_order"`.
  /// Returns tracking info; the backend computes delivery charge and the
  /// discounted price server-side, so those come back in the response
  /// rather than being sent by the client.
  Future<({String trackingId, double deliveryCharge, double discountedPrice})> place({
    required int productId,
    int quantity = 1,
    required ShippingAddress shippingAddress,
    String paymentMethod = 'bkash',
    String? senderNumber,
    String? transactionId,
    String? whatsappPhone,
  }) async {
    final res = await _client.post<Map<String, dynamic>>('/pre-orders', data: {
      'productId': productId,
      'quantity': quantity,
      'shippingAddress': shippingAddress.toJson(),
      'paymentMethod': paymentMethod,
      if (senderNumber != null) 'senderNumber': senderNumber,
      if (transactionId != null) 'transactionId': transactionId,
      if (whatsappPhone != null) 'whatsappPhone': whatsappPhone,
    });
    return (
      trackingId: res.data!['trackingId'] as String,
      deliveryCharge: (res.data!['deliveryCharge'] as num).toDouble(),
      discountedPrice: (res.data!['discountedPrice'] as num).toDouble(),
    );
  }

  /// Requires the user to be signed in — the backend rejects with 401
  /// otherwise (see `getAuth(req)?.userId` check in preOrders.ts).
  Future<List<PreOrder>> myPreOrders() async {
    final res = await _client.get<List<dynamic>>('/pre-orders/my');
    return (res.data ?? [])
        .map((e) => PreOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PreOrder> trackByTrackingId(String trackingId) async {
    final res = await _client.get<Map<String, dynamic>>('/pre-orders/track/$trackingId');
    return PreOrder.fromJson(res.data!);
  }
}
