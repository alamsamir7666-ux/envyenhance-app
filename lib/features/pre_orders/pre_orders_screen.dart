import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pre_order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/async_states.dart';

final myPreOrdersProvider = FutureProvider<List<PreOrder>>((ref) async {
  ref.watch(authIdentityProvider);
  final repo = ref.watch(preOrdersRepositoryProvider);
  return repo.myPreOrders();
});

class PreOrdersScreen extends ConsumerWidget {
  const PreOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preOrdersAsync = ref.watch(myPreOrdersProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('My Pre-Orders')),
      body: preOrdersAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(myPreOrdersProvider),
        ),
        data: (preOrders) {
          if (preOrders.isEmpty) {
            return const EmptyView(
              icon: Icons.schedule_outlined,
              title: 'No pre-orders',
              subtitle: 'Products available for pre-order will show up here once reserved.',
            );
          }
          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () async => ref.invalidate(myPreOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: preOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _PreOrderTile(preOrder: preOrders[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PreOrderTile extends StatelessWidget {
  const _PreOrderTile({required this.preOrder});
  final PreOrder preOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final statusColor = switch (preOrder.status) {
      'shipped' || 'delivered' => brand.sage,
      'cancelled' => theme.colorScheme.error,
      _ => brand.gold,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  preOrder.productName,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              AppBadge.soft(
                text: preOrder.status.toUpperCase(),
                color: statusColor,
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Tracking: ${preOrder.trackingId}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            'Qty ${preOrder.quantity} · ${formatTaka(preOrder.total)}',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
