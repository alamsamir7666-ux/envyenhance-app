import 'package:clerk_flutter/clerk_flutter.dart';
import 'auth_service.dart';

/// Wraps [ClerkAuthState] (from the `clerk_flutter` package) to satisfy
/// our [AuthService] interface.
///
/// NOTE: `clerk_flutter` is a young package and its exact API surface may
/// have shifted between versions. If `flutter pub get` or the build fails
/// on this file, check the installed version's docs
/// (https://pub.dev/packages/clerk_flutter) for the current class/method
/// names — likely candidates are `ClerkAuthState`, `ClerkAuth.of(context)`,
/// or a `ClerkAuthProvider` inherited widget. The shape of this class
/// (isSignedIn / userId / getToken / signOut) should stay the same either
/// way, so only the internals of each method need patching, not any
/// calling code elsewhere in the app.
class ClerkAuthServiceImpl extends AuthService {
  ClerkAuthServiceImpl(this._authState) {
    _authState.addListener(notifyListeners);
  }

  final ClerkAuthState _authState;

  @override
  bool get isSignedIn => _authState.isSignedIn;

  @override
  String? get userId => _authState.user?.id;

  @override
  String? get email => _authState.user?.primaryEmailAddress?.emailAddress;

  @override
  String? get firstName => _authState.user?.firstName;

  @override
  String? get lastName => _authState.user?.lastName;

  @override
  Future<String?> getToken() async {
    if (!isSignedIn) return null;
    return _authState.session?.getToken();
  }

  @override
  Future<void> signOut() async {
    await _authState.signOut();
  }

  @override
  void dispose() {
    _authState.removeListener(notifyListeners);
    super.dispose();
  }
}
