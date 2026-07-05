import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/auth_repository.dart';
import 'core/api/api_client.dart';
import 'core/auth/mobile_auth_service.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/update/update_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Push notifications are a nicety, not core functionality — if
  // google-services.json hasn't been added yet (see lib/core/push/
  // push_service.dart for setup steps), this fails silently and the rest
  // of the app works exactly as before.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[push] Firebase.initializeApp failed (non-fatal): $e');
  }
  runApp(const _AppBootstrap());
}

/// Wires up the auth service before the rest of the app's providers are
/// created, since [ApiClient] depends on [AuthService.getToken] for every
/// request. Unlike the earlier Clerk-based bootstrap, this has no network
/// dependency at startup — [MobileAuthServiceImpl] only reads from local
/// secure storage, so there's no init-hang risk here.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  // A bootstrap-only ApiClient (no auth token) purely to construct the
  // AuthRepository, which itself has no auth requirement (sign-in/sign-up
  // are public endpoints). The real, token-aware ApiClient is built by
  // apiClientProvider once authServiceProvider is available.
  late final MobileAuthServiceImpl _authService;

  @override
  void initState() {
    super.initState();
    final bootstrapClient = ApiClient();
    _authService = MobileAuthServiceImpl(AuthRepository(bootstrapClient));
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWith((ref) => _authService),
      ],
      child: const EnvyEnhanceApp(),
    );
  }
}

class EnvyEnhanceApp extends ConsumerStatefulWidget {
  const EnvyEnhanceApp({super.key});

  @override
  ConsumerState<EnvyEnhanceApp> createState() => _EnvyEnhanceAppState();
}

class _EnvyEnhanceAppState extends ConsumerState<EnvyEnhanceApp> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: check for an update once, after the first frame, so
    // it never delays app startup or blocks the UI thread. Failures are
    // swallowed inside UpdateService itself — this is a background nicety,
    // not something that should ever interrupt the shopping experience.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(updateServiceProvider).checkForUpdate();

      final pushService = ref.read(pushServiceProvider);
      await pushService.initialize();
      await pushService.syncTokenForCurrentUser();

      // Re-sync whenever sign-in state changes (sign in → register this
      // device; sign out → unregister it so the old user's device stops
      // receiving notifications meant for them).
      ref.listenManual(authIdentityProvider, (previous, next) {
        if (previous?.isSignedIn != next.isSignedIn) {
          pushService.syncTokenForCurrentUser();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
