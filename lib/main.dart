import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/auth_repository.dart';
import 'core/api/api_client.dart';
import 'core/auth/mobile_auth_service.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/update/update_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateServiceProvider).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
