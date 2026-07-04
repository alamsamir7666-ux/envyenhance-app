import 'api_client.dart';

class StockAlertsRepository {
  StockAlertsRepository(this._client);
  final ApiClient _client;

  /// Registers [email] to be notified when [productId] is back in stock.
  /// Returns the backend's confirmation message. Note: per the backend,
  /// a phone number can be submitted in place of an email by suffixing
  /// it with "@phone.notify" (the website's WhatsApp-notify convention) —
  /// exposed here as [phone] for a cleaner call site.
  Future<String> subscribe({
    required int productId,
    String? email,
    String? phone,
  }) async {
    final contact = email ?? (phone != null ? '$phone@phone.notify' : null);
    if (contact == null) {
      throw ArgumentError('Either email or phone must be provided');
    }
    final res = await _client.post<Map<String, dynamic>>('/stock-alerts', data: {
      'productId': productId,
      'email': contact,
    });
    return res.data!['message'] as String;
  }
}
