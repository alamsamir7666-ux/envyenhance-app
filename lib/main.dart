import 'dart:async';

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

/// Initializes Clerk before the rest of the app runs. Clerk's own
/// `ClerkAuth` widget shows its configured `loading` widget while
/// `ClerkAuthState.create()` resolves, but that call has no built-in
/// timeout — if Clerk's servers are unreachable or slow, the app would
/// otherwise hang on the loading widget forever with no feedback. We
/// race init against a timer and show a real error screen with retry
/// if it doesn't finish in time.
class _ClerkBootstrap extends StatefulWidget {
  const _ClerkBootstrap();

  @override
  State<_ClerkBootstrap> createState() => _ClerkBootstrapState();
}

class _ClerkBootstrapState extends State<_ClerkBootstrap> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _waitForClerkOrTimeout();
  }

  Future<void> _waitForClerkOrTimeout() {
    // ClerkAuth itself doesn't expose a plain Future for init completion,
    // so we just bound how long we're willing to show a spinner before
    // treating it as failed. The ClerkAuth widget below will still keep
    // trying in the background; this only controls what WE show.
    return Future.delayed(const Duration(seconds: 20));
  }

  void _retry() {
    setState(() {
      _initFuture = _waitForClerkOrTimeout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: AppConfig.clerkPublishableKey,
        loading: const _ClerkLoadingScreen(),
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

/// Shown by Clerk while `ClerkAuthState.create()` is resolving. After a
/// timeout, switches from a spinner to an explicit error message with a
/// retry button so the app is never silently stuck.
class _ClerkLoadingScreen extends StatefulWidget {
  const _ClerkLoadingScreen();

  @override
  State<_ClerkLoadingScreen> createState() => _ClerkLoadingScreenState();
}

class _ClerkLoadingScreenState extends State<_ClerkLoadingScreen> {
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() => _timedOut = false);
    _timer = Timer(const Duration(seconds: 20), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: _timedOut
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text(
                        'Taking longer than expected to connect.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _retry, child: const Text('Retry')),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: AppColors.primary),
        ),
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
