import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/clerk_auth_service.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const _ClerkBootstrap());
}

/// Initializes Clerk before the rest of the app (and its Riverpod
/// providers) can run, since [ApiClient] depends on being able to fetch
/// a session token from Clerk on every request.
///
/// NOTE: `ClerkAuth` / `ClerkAuthState` below are the expected entry
/// points for `clerk_flutter`, but package APIs can shift between
/// versions. If this doesn't compile against the version installed by
/// `flutter pub get`, check https://pub.dev/packages/clerk_flutter for
/// the current initialization pattern — likely still a top-level
/// ClerkAuth widget wrapping the app with a publishableKey, exposing an
/// InheritedWidget-style state object. Only this file and
/// core/auth/clerk_auth_service.dart should need adjusting.
class _ClerkBootstrap extends StatelessWidget {
  const _ClerkBootstrap();

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: AppConfig.clerkPublishableKey,
      ),
      child: Builder(
        builder: (context) {
          final authState = ClerkAuth.of(context);
          return ProviderScope(
            overrides: [
              authServiceProvider.overrideWithValue(
                ClerkAuthServiceImpl(authState),
              ),
            ],
            child: const EnvyEnhanceApp(),
          );
        },
      ),
    );
  }
}

class EnvyEnhanceApp extends ConsumerWidget {
  const EnvyEnhanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
