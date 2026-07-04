import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/subscription.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import 'subscriptions_providers.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({required this.subscriptionId, super.key});
  final int subscriptionId;

  @override
  ConsumerState<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends ConsumerState<SubscriptionDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      final repo = ref.read(subscriptionsRepositoryProvider);
      await repo.update(widget.subscriptionId, status: status);
      ref.invalidate(subscriptionDetailProvider(widget.subscriptionId));
      ref.invalidate(mySubscriptionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmCancel() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text('This cannot be undone. You can always create a new subscription later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel subscription', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _updateStatus('cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionDetailProvider(widget.subscriptionId));
    final theme = Theme.of(context);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: subAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(subscriptionDetailProvider(widget.subscriptionId)),
        ),
        data: (sub) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brand.roseSurface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${sub.status.toUpperCase()}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sub.discountPercent}% subscriber discount applied',
                      style: TextStyle(color: brand.sage, fontWeight: FontWeight.w600),
                    ),
                    if (sub.isActive) ...[
                      const SizedBox(height: 8),
                      Text('Next order: ${formatDate(sub.nextOrderDate)}'),
                    ],
                    if (sub.orderCount > 0) ...[
                      const SizedBox(height: 4),
                      Text('${sub.orderCount} order${sub.orderCount == 1 ? '' : 's'} delivered so far'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Items', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final item in sub.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('${item.productName} × ${item.quantity}')),
                      Text(formatTaka(item.price * item.quantity)),
                    ],
                  ),
                ),
              const Divider(height: 32),
              Text('Delivery Address', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(sub.shippingAddress.fullName),
              Text(sub.shippingAddress.phone),
              Text('${sub.shippingAddress.street}, ${sub.shippingAddress.city}'),
              const SizedBox(height: 24),
              if (sub.status != 'cancelled') ...[
                if (sub.isActive)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isUpdating ? null : () => _updateStatus('paused'),
                      child: const Text('Pause subscription'),
                    ),
                  )
                else if (sub.isPaused)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : () => _updateStatus('active'),
                      child: const Text('Resume subscription'),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isUpdating ? null : _confirmCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('Cancel subscription'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
