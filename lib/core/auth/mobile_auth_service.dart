import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/auth_repository.dart';
import 'auth_service.dart';

/// Auth backed by our own backend's `/api/mobile-auth/*` endpoints rather
/// than Clerk's Flutter SDK directly (see clerk_flutter's beta-stage
/// initialization issues — this approach verifies credentials against
/// Clerk server-side via the backend, then uses a JWT minted by our own
/// server as the app's session token).
///
/// The JWT is persisted in secure, encrypted on-device storage so the
/// user stays signed in across app restarts.
class MobileAuthServiceImpl extends AuthService {
  MobileAuthServiceImpl(this._repository) {
    _restoreSession();
  }

  final AuthRepository _repository;
  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'mobile_auth_token';
  static const _userIdKey = 'mobile_auth_user_id';
  static const _emailKey = 'mobile_auth_email';
  static const _firstNameKey = 'mobile_auth_first_name';
  static const _lastNameKey = 'mobile_auth_last_name';

  String? _token;
  String? _userId;
  String? _email;
  String? _firstName;
  String? _lastName;
  bool _isRestoring = true;

  @override
  bool get isSignedIn => _token != null;

  @override
  String? get userId => _userId;

  @override
  String? get email => _email;

  @override
  String? get firstName => _firstName;

  @override
  String? get lastName => _lastName;

  /// Whether the service is still loading a previously-saved session from
  /// secure storage. The router/UI can use this to show a brief loading
  /// state on cold start instead of flashing a "signed out" state first.
  bool get isRestoring => _isRestoring;

  Future<void> _restoreSession() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        _token = token;
        _userId = await _storage.read(key: _userIdKey);
        _email = await _storage.read(key: _emailKey);
        _firstName = await _storage.read(key: _firstNameKey);
        _lastName = await _storage.read(key: _lastNameKey);
      }
    } catch (_) {
      // Secure storage unavailable/corrupted — treat as signed out rather
      // than crashing the app on startup.
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession(MobileAuthResult result) async {
    _token = result.token;
    _userId = result.user.id;
    _email = result.user.email;
    _firstName = result.user.firstName;
    _lastName = result.user.lastName;

    await _storage.write(key: _tokenKey, value: result.token);
    await _storage.write(key: _userIdKey, value: result.user.id);
    await _storage.write(key: _emailKey, value: result.user.email);
    if (result.user.firstName != null) {
      await _storage.write(key: _firstNameKey, value: result.user.firstName);
    }
    if (result.user.lastName != null) {
      await _storage.write(key: _lastNameKey, value: result.user.lastName);
    }

    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    final result = await _repository.signIn(email: email, password: password);
    await _persistSession(result);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final result = await _repository.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    await _persistSession(result);
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> signOut() async {
    _token = null;
    _userId = null;
    _email = null;
    _firstName = null;
    _lastName = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
