import '../api/api_client.dart';

class MobileAuthUser {
  MobileAuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory MobileAuthUser.fromJson(Map<String, dynamic> json) => MobileAuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
      );

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
}

class MobileAuthResult {
  MobileAuthResult({required this.token, required this.user});
  final String token;
  final MobileAuthUser user;
}

/// Talks to our own backend's `/api/mobile-auth/*` endpoints — not Clerk
/// directly. See `artifacts/api-server/src/routes/mobileAuth.ts` on the
/// backend for the server-side half of this flow.
class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<MobileAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/mobile-auth/sign-in',
      data: {'email': email, 'password': password},
    );
    final data = res.data!;
    return MobileAuthResult(
      token: data['token'] as String,
      user: MobileAuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<MobileAuthResult> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/mobile-auth/sign-up',
      data: {
        'email': email,
        'password': password,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      },
    );
    final data = res.data!;
    return MobileAuthResult(
      token: data['token'] as String,
      user: MobileAuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
