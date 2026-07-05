import 'api_client.dart';

/// Talks to the backend's `/api/mobile-push/*` endpoints (see
/// `artifacts/api-server/src/routes/mobilePush.ts`) to register this
/// device's FCM token so the server can send it push notifications (order
/// status changes, pre-order arrivals).
class PushRepository {
  PushRepository(this._client);
  final ApiClient _client;

  Future<void> registerToken(String token, {String platform = 'android'}) async {
    await _client.post<Map<String, dynamic>>('/mobile-push/register', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterToken(String token) async {
    await _client.post<Map<String, dynamic>>('/mobile-push/unregister', data: {
      'token': token,
    });
  }
}
