import '../models/wishlist_loyalty.dart';
import 'api_client.dart';

class WishlistRepository {
  WishlistRepository(this._client);
  final ApiClient _client;

  Future<List<WishlistItem>> getWishlist() async {
    final res = await _client.get<List<dynamic>>('/wishlist');
    return (res.data ?? [])
        .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(int productId) async {
    await _client.post<dynamic>('/wishlist/$productId');
  }

  Future<void> remove(int productId) async {
    await _client.delete<dynamic>('/wishlist/$productId');
  }
}
