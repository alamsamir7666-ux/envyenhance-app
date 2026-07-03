import 'package:flutter/foundation.dart';

/// Abstraction over the auth backend so the rest of the app never touches
/// networking or storage details directly. See MobileAuthServiceImpl for
/// the concrete implementation, which talks to our own backend's
/// `/api/mobile-auth/*` endpoints (themselves backed by Clerk server-side).
abstract class AuthService extends ChangeNotifier {
  bool get isSignedIn;
  String? get userId; // Clerk user id
  String? get email;
  String? get firstName;
  String? get lastName;

  /// Returns the current session JWT to send as a Bearer token to the
  /// EnvyEnhance API, or null if signed out. The backend's `requireAuth`
  /// middleware verifies this token via Clerk's backend SDK.
  Future<String?> getToken();

  Future<void> signOut();
}
