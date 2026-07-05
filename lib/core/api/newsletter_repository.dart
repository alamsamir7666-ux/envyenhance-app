import 'api_client.dart';

class NewsletterRepository {
  NewsletterRepository(this._client);
  final ApiClient _client;

  Future<void> subscribe(String email) async {
    await _client.post<dynamic>('/newsletter/subscribe', data: {'email': email});
  }

  Future<void> unsubscribe(String email) async {
    await _client.post<dynamic>('/newsletter/unsubscribe', data: {'email': email});
  }
}
