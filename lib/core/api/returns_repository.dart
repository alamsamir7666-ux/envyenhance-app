import '../models/return_request.dart';
import 'api_client.dart';

class ReturnRequestException implements Exception {
  ReturnRequestException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ReturnsRepository {
  ReturnsRepository(this._client);
  final ApiClient _client;

  /// Requests a return for [orderId]. The backend enforces: order must
  /// belong to the current user, must be "delivered", within a 7-day
  /// return window, and not already have a return request — all
  /// surfaced here as [ReturnRequestException] with the exact server
  /// message (e.g. "Return window has expired...").
  Future<ReturnRequest> request({required int orderId, required String reason}) async {
    try {
      final res = await _client.post<Map<String, dynamic>>('/returns', data: {
        'orderId': orderId,
        'reason': reason,
      });
      return ReturnRequest.fromJson(res.data!);
    } on ApiException catch (e) {
      throw ReturnRequestException(e.message);
    }
  }

  Future<List<ReturnRequest>> myReturns() async {
    final res = await _client.get<List<dynamic>>('/returns/me');
    return (res.data ?? [])
        .map((e) => ReturnRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
