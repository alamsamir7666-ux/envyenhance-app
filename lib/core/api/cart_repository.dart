import '../models/cart.dart';
import 'api_client.dart';

class CartRepository {
  CartRepository(this._client);
  final ApiClient _client;

  Future<Cart> getCart() async {
    final res = await _client.get<Map<String, dynamic>>('/cart');
    return Cart.fromJson(res.data!);
  }

  /// [variantId] is optional — omit it for products without variants,
  /// which matches existing behavior exactly.
  Future<Cart> addItem(int productId, int quantity, {int? variantId}) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/cart/items',
      data: {
        'productId': productId,
        'quantity': quantity,
        if (variantId != null) 'variantId': variantId,
      },
    );
    return Cart.fromJson(res.data!);
  }

  Future<Cart> updateQuantity(int productId, int quantity, {int? variantId}) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/cart/items/$productId',
      data: {'quantity': quantity},
      query: variantId != null ? {'variantId': variantId} : null,
    );
    return Cart.fromJson(res.data!);
  }

  Future<Cart> removeItem(int productId, {int? variantId}) async {
    final res = await _client.delete<Map<String, dynamic>>(
      '/cart/items/$productId',
      query: variantId != null ? {'variantId': variantId} : null,
    );
    return Cart.fromJson(res.data!);
  }

  Future<void> clearCart() async {
    await _client.delete<Map<String, dynamic>>('/cart');
  }
}
