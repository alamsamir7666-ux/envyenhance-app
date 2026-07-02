import '../models/wishlist_loyalty.dart';
import 'api_client.dart';

class LoyaltyRepository {
  LoyaltyRepository(this._client);
  final ApiClient _client;

  Future<LoyaltyStatus> myStatus() async {
    final res = await _client.get<Map<String, dynamic>>('/loyalty/me');
    return LoyaltyStatus.fromJson(res.data!);
  }
}
