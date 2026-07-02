import 'package:flutter/foundation.dart';

/// Abstraction over the auth provider (Clerk) so the rest of the app
/// never touches the Clerk SDK directly. This makes it easy to patch if
/// the Clerk Flutter package's exact API differs from what's written
/// here — only this file (and clerk_auth_service.dart) would need edits.
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
