import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/email_preferences.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/widgets/async_states.dart';

final emailPrefsProvider =
    FutureProvider<EmailPreferences>((ref) async {
  ref.watch(authIdentityProvider);
  return ref.watch(emailPreferencesRepositoryProvider).get();
});

class EmailPreferencesScreen extends ConsumerStatefulWidget {
  const EmailPreferencesScreen({super.key});

  @override
  ConsumerState<EmailPreferencesScreen> createState() =>
      _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState
    extends ConsumerState<EmailPreferencesScreen> {
  EmailPreferences? _local;
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_local == null) return;
    setState(() { _saving = true; _saved = false; });
    try {
      await ref
          .read(emailPreferencesRepositoryProvider)
          .update(_local!);
      ref.invalidate(emailPrefsProvider);
      if (mounted) setState(() => _saved = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saved = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final prefsAsync = ref.watch(emailPrefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Preferences'),
        actions: [
          if (_local != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _saved ? '✓ Saved' : 'Save',
                        style: TextStyle(
                            color: _saved ? brand.sage : brand.gold,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
        ],
      ),
      body: prefsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (prefs) {
          _local ??= prefs;
          final p = _local!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Choose which emails you receive from EnvyEnhance.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _PrefTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Order Updates',
                subtitle: 'Confirmations, shipping, delivery notifications',
                value: p.orderUpdates,
                onChanged: (v) =>
                    setState(() => _local = p.copyWith(orderUpdates: v)),
              ),
              _PrefTile(
                icon: Icons.local_offer_outlined,
                title: 'Promotions & Sales',
                subtitle: 'Flash sales, discount codes, seasonal offers',
                value: p.promotions,
                onChanged: (v) =>
                    setState(() => _local = p.copyWith(promotions: v)),
              ),
              _PrefTile(
                icon: Icons.notifications_outlined,
                title: 'Restock Alerts',
                subtitle: 'When products on your wish list come back in stock',
                value: p.restockAlerts,
                onChanged: (v) =>
                    setState(() => _local = p.copyWith(restockAlerts: v)),
              ),
              _PrefTile(
                icon: Icons.email_outlined,
                title: 'Newsletter',
                subtitle: 'Beauty tips, J-beauty guides, new arrivals digest',
                value: p.newsletter,
                onChanged: (v) =>
                    setState(() => _local = p.copyWith(newsletter: v)),
              ),
              _PrefTile(
                icon: Icons.shopping_cart_outlined,
                title: 'Abandoned Cart',
                subtitle: 'Reminders when you leave items in your cart',
                value: p.abandonedCart,
                onChanged: (v) =>
                    setState(() => _local = p.copyWith(abandonedCart: v)),
              ),
              _PrefTile(
                icon: Icons.stars_outlined,
                title: 'Loyalty Updates',
                subtitle: 'Points earned, tier upgrades, reward expiry',
                value: p.loyaltyUpdates,
                onChanged: (v) =>
                    setState(() => _local = p.copyWith(loyaltyUpdates: v)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_saved ? '✓ Preferences Saved' : 'Save Preferences',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: brand.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: brand.gold,
          ),
        ],
      ),
    );
  }
}
