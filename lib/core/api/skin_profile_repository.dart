import '../models/skin_profile.dart';
import 'api_client.dart';

class SkinProfileRepository {
  SkinProfileRepository(this._client);
  final ApiClient _client;

  /// Returns null if the user hasn't taken the quiz yet (backend 404s).
  Future<SkinProfile?> myProfile() async {
    try {
      final res = await _client.get<Map<String, dynamic>>('/skin-profile');
      return SkinProfile.fromJson(res.data!);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<SkinProfile> save({
    required String feel,
    required String sensitivity,
    required String concern,
    required String routine,
  }) async {
    final res = await _client.post<Map<String, dynamic>>('/skin-profile', data: {
      'feel': feel,
      'sensitivity': sensitivity,
      'concern': concern,
      'routine': routine,
    });
    return SkinProfile.fromJson(res.data!);
  }

  Future<void> reset() async {
    await _client.delete<void>('/skin-profile');
  }
}
