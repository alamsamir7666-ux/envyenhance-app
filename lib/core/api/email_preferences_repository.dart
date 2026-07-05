import '../models/email_preferences.dart';
import 'api_client.dart';

class EmailPreferencesRepository {
  EmailPreferencesRepository(this._client);
  final ApiClient _client;

  Future<EmailPreferences> get() async {
    final res = await _client.get<Map<String, dynamic>>('/email-preferences');
    return EmailPreferences.fromJson(res.data!);
  }

  Future<EmailPreferences> update(EmailPreferences prefs) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/email-preferences',
      data: prefs.toJson(),
    );
    return EmailPreferences.fromJson(res.data!);
  }
}
