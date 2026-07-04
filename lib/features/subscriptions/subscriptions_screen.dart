import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/async_states.dart';
import 'subscriptions_providers.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(mySubscriptionsProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscriptions')),
      body: subsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(mySubscriptionsProvider),
        ),
        data: (subs) {
          if (subs.isEmpty) {
            return const EmptyView(
              icon: Icons.autorenew,
              title: 'No subscriptions yet',
              subtitle:
                  'Set up recurring delivery for your favorite products and save 10% on every order.',
            );
          }
          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () async => ref.invalidate(mySubscriptionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: subs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final sub = subs[i];
                final theme = Theme.of(context);
                final statusColor = switch (sub.status) {
                  'active' => brand.sage,
                  'paused' => brand.gold,
                  _ => brand.textSecondary,
                };
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/subscriptions/${sub.id}'),
                  child: Container(
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
                            Text(
                              '${sub.items.length} item${sub.items.length == 1 ? '' : 's'}',
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            AppBadge.soft(
                              text: sub.status.toUpperCase(),
                              color: statusColor,
                              textColor: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sub.items.map((i) => i.productName).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_frequencyLabel(sub.frequency)} · ${formatTaka(sub.totalAmount)}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            if (sub.isActive)
                              Text(
                                'Next: ${formatDateTime(sub.nextOrderDate)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _frequencyLabel(String frequency) => switch (frequency) {
        'weekly' => 'Weekly',
        'biweekly' => 'Every 2 weeks',
        'monthly' => 'Monthly',
        _ => frequency,
      };
}
