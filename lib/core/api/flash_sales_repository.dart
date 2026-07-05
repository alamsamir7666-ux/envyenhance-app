import '../models/flash_sale.dart';
import 'api_client.dart';

class FlashSalesRepository {
  FlashSalesRepository(this._client);
  final ApiClient _client;

  Future<List<FlashSaleProduct>> getFlashSales() async {
    final res = await _client.get<List<dynamic>>('/flash-sales');
    return (res.data ?? [])
        .map((e) => FlashSaleProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
