import '../models/order.dart';
import '../models/subscription.dart';
import 'api_client.dart';

class SubscriptionsRepository {
  SubscriptionsRepository(this._client);
  final ApiClient _client;

  Future<List<Subscription>> myList() async {
    final res = await _client.get<List<dynamic>>('/subscriptions');
    return (res.data ?? [])
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Subscription> getById(int id) async {
    final res = await _client.get<Map<String, dynamic>>('/subscriptions/$id');
    return Subscription.fromJson(res.data!);
  }

  Future<Subscription> create({
    required List<SubscriptionItem> items,
    required String frequency,
    required ShippingAddress shippingAddress,
    String paymentMethod = 'cod',
    String? notes,
  }) async {
    final res = await _client.post<Map<String, dynamic>>('/subscriptions', data: {
      'items': items.map((i) => i.toJson()).toList(),
      'frequency': frequency,
      'shippingAddress': shippingAddress.toJson(),
      'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
    });
    return Subscription.fromJson(res.data!);
  }

  /// Updates status (pause/resume/cancel), frequency, address, or notes.
  /// Pass only the fields that should change.
  Future<Subscription> update(
    int id, {
    String? status,
    String? frequency,
    ShippingAddress? shippingAddress,
    String? notes,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>('/subscriptions/$id', data: {
      if (status != null) 'status': status,
      if (frequency != null) 'frequency': frequency,
      if (shippingAddress != null) 'shippingAddress': shippingAddress.toJson(),
      if (notes != null) 'notes': notes,
    });
    return Subscription.fromJson(res.data!);
  }

  Future<void> delete(int id) async {
    await _client.delete<void>('/subscriptions/$id');
  }
}
