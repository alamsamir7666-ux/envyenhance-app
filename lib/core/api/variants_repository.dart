import '../models/variant.dart';
import 'api_client.dart';

class VariantsRepository {
  VariantsRepository(this._client);
  final ApiClient _client;

  Future<List<ProductVariant>> getVariants(int productId) async {
    final res = await _client.get<List<dynamic>>('/products/$productId/variants');
    return (res.data ?? [])
        .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
