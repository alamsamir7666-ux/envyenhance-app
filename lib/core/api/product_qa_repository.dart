import '../models/product_qa.dart';
import 'api_client.dart';

class ProductQAException implements Exception {
  ProductQAException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProductQARepository {
  ProductQARepository(this._client);
  final ApiClient _client;

  Future<List<ProductQuestion>> forProduct(int productId) async {
    final res = await _client.get<List<dynamic>>('/products/$productId/qa');
    return (res.data ?? [])
        .map((e) => ProductQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Posts a new question. The backend enforces a 1-hour cooldown per
  /// user across all products (returns 429 if exceeded) — surfaced here
  /// as [ProductQAException] with the server's exact wait-time message.
  Future<void> ask({required int productId, required String question}) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/products/$productId/qa',
        data: {'question': question},
      );
    } on ApiException catch (e) {
      throw ProductQAException(e.message);
    }
  }
}
