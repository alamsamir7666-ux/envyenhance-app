import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// Sign-in / sign-up screen. Delegates the actual auth UI to Clerk's
/// pre-built `ClerkAuthentication` widget. `ClerkAuthentication` has no
/// sign-in-complete callback, so we wrap it in `ClerkAuthBuilder` and
/// react when `signedInBuilder` fires (i.e. a Clerk user becomes
/// available) to navigate away.
class SignInScreen extends StatelessWidget {
  const SignInScreen({this.redirectTo, super.key});

  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to track orders, save your wishlist, and earn loyalty points.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClerkAuthBuilder(
                signedInBuilder: (context, authState) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    if (redirectTo != null) {
                      context.go(redirectTo!);
                    } else {
                      context.go('/');
                    }
                  });
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                },
                signedOutBuilder: (context, authState) => const ClerkAuthentication(),
                builder: (context, authState) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
