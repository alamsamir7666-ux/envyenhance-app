import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// Sign-in / sign-up screen. Delegates the actual auth UI to Clerk's
/// pre-built `ClerkAuthentication` widget so we inherit Clerk's handling
/// of email/password, verification codes, social providers (whatever is
/// enabled in the Clerk dashboard for this project), and error states —
/// rather than re-implementing auth forms by hand.
///
/// NOTE: `ClerkAuthentication` is the expected widget name in
/// `clerk_flutter`, but if the installed version exposes a different
/// widget (check pub.dev for the current version), swap it in here —
/// this screen is the only place that needs to change.
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
              child: ClerkAuthentication(
                onSignInComplete: (context) {
                  if (redirectTo != null) {
                    context.go(redirectTo!);
                  } else {
                    context.go('/');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
