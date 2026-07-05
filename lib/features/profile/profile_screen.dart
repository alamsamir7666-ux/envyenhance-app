import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/widgets/async_states.dart';
import 'update_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);

    if (!auth.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EmptyView(
              icon: Icons.person_outline,
              title: 'You\'re not signed in',
              subtitle: 'Sign in to view your profile, orders, and rewards.',
              actionLabel: 'Sign In',
              onAction: () => context.push('/sign-in'),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: Icons.article_outlined,
              label: 'Skincare Journal',
              onTap: () => context.push('/blog'),
            ),
            const SizedBox(height: 16),
            const UpdateCard(),
          ],
        ),
      );
    }

    final userAsync = ref.watch(_meProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(_meProvider),
        ),
        data: (user) {
          final brand = context.brand;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: brand.roseSurface,
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: brand.roseText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'My Orders',
                onTap: () => context.push('/orders'),
              ),
              _MenuTile(
                icon: Icons.favorite_border,
                label: 'Wishlist',
                onTap: () => context.push('/wishlist'),
              ),
              _MenuTile(
                icon: Icons.stars_outlined,
                label: 'Loyalty Points',
                onTap: () => context.push('/loyalty'),
              ),
              _MenuTile(
                icon: Icons.autorenew,
                label: 'My Subscriptions',
                onTap: () => context.push('/subscriptions'),
              ),
              _MenuTile(
                icon: Icons.schedule_outlined,
                label: 'Pre-Orders',
                onTap: () => context.push('/pre-orders'),
              ),
              _MenuTile(
                icon: Icons.assignment_return_outlined,
                label: 'Returns',
                onTap: () => context.push('/returns'),
              ),
              const Divider(height: 32),
              _MenuTile(
                icon: Icons.card_giftcard_outlined,
                label: 'Gift Cards',
                onTap: () => context.push('/gift-cards'),
              ),
              _MenuTile(
                icon: Icons.face_retouching_natural_outlined,
                label: 'Skin Profile Quiz',
                onTap: () => context.push('/skin-quiz'),
              ),
              _MenuTile(
                icon: Icons.people_outline,
                label: 'Refer & Earn',
                onTap: () => context.push('/referrals'),
              ),
              _MenuTile(
                icon: Icons.article_outlined,
                label: 'Skincare Journal',
                onTap: () => context.push('/blog'),
              ),
              const Divider(height: 32),
              _MenuTile(
                icon: Icons.location_on_outlined,
                label: 'Saved Addresses',
                onTap: () => context.push('/track-order'),
              ),
              _MenuTile(
                icon: Icons.email_outlined,
                label: 'Email Preferences',
                onTap: () => context.push('/email-preferences'),
              ),
              _MenuTile(
                icon: Icons.location_on_outlined,
                label: 'Saved Addresses',
                onTap: () => context.push('/addresses'),
              ),
              const _ThemeModeTile(),
              const Divider(height: 32),
              const UpdateCard(),
              const SizedBox(height: 24),
              _MenuTile(
                icon: Icons.logout,
                label: 'Sign Out',
                color: Theme.of(context).colorScheme.error,
                onTap: () async {
                  final errorColor = Theme.of(context).colorScheme.error;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Sign Out', style: TextStyle(color: errorColor)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await auth.signOut();
                    if (context.mounted) context.go('/');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

final _meProvider = FutureProvider((ref) async {
  // Watching authIdentityProvider (not just calling usersRepositoryProvider)
  // is what makes this provider correctly refetch when the signed-in user
  // changes — Riverpod re-runs this builder whenever the watched identity
  // changes, discarding any previously cached user data from a prior
  // session instead of serving it stale.
  ref.watch(authIdentityProvider);
  final repo = ref.watch(usersRepositoryProvider);
  return repo.me();
});

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  String _label(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.dark_mode_outlined, color: theme.colorScheme.onSurface),
      title: Text('Appearance', style: theme.textTheme.bodyLarge),
      trailing: DropdownButton<ThemeMode>(
        value: mode,
        underline: const SizedBox.shrink(),
        items: ThemeMode.values
            .map((m) => DropdownMenuItem(value: m, child: Text(_label(m))))
            .toList(),
        onChanged: (m) {
          if (m != null) ref.read(themeModeProvider.notifier).setMode(m);
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? theme.colorScheme.onSurface),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(color: color),
      ),
      trailing: Icon(Icons.chevron_right, color: context.brand.textSecondary),
      onTap: onTap,
    );
  }
}
