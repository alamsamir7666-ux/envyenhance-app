import '../models/cart.dart';
import 'api_client.dart';

class CartRepository {
  CartRepository(this._client);
  final ApiClient _client;

  Future<Cart> getCart() async {
    final res = await _client.get<Map<String, dynamic>>('/cart');
    return Cart.fromJson(res.data!);
  }

  Future<Cart> addItem(int productId, int quantity) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/cart/items',
      data: {'productId': productId, 'quantity': quantity},
    );
    return Cart.fromJson(res.data!);
  }

  Future<Cart> updateQuantity(int productId, int quantity) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/cart/items/$productId',
      data: {'quantity': quantity},
    );
    return Cart.fromJson(res.data!);
  }

  Future<Cart> removeItem(int productId) async {
    final res = await _client.delete<Map<String, dynamic>>(
      '/cart/items/$productId',
    );
    return Cart.fromJson(res.data!);
  }

  Future<void> clearCart() async {
    await _client.delete<Map<String, dynamic>>('/cart');
  }
}
