import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pre_order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';

final preOrderDetailProvider =
    FutureProvider.family<PreOrder, String>((ref, trackingId) async {
  return ref.watch(preOrdersRepositoryProvider).trackByTrackingId(trackingId);
});

const _steps = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];

class PreOrderDetailScreen extends ConsumerWidget {
  const PreOrderDetailScreen({super.key, required this.trackingId});
  final String trackingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(preOrderDetailProvider(trackingId));
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Order Detail')),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(preOrderDetailProvider(trackingId)),
        ),
        data: (order) => RefreshIndicator(
          color: brand.gold,
          onRefresh: () async => ref.invalidate(preOrderDetailProvider(trackingId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(order: order),
              const SizedBox(height: 12),
              _TrackingCard(order: order),
              const SizedBox(height: 12),
              _ProductCard(order: order),
              const SizedBox(height: 12),
              _PaymentCard(order: order),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});
  final PreOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final currentStep = _steps.indexOf(order.status);
    final isCancelled = order.status == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text('Order Status',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? theme.colorScheme.error.withValues(alpha: 0.1)
                      : brand.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCancelled ? theme.colorScheme.error : brand.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isCancelled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: theme.colorScheme.error, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('This pre-order has been cancelled.')),
                ],
              ),
            )
          else
            Row(
              children: List.generate(_steps.length, (i) {
                final done = i < currentStep;
                final active = i == currentStep;
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: done || active ? brand.gold : theme.dividerColor,
                              ),
                            ),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? brand.gold
                                  : active
                                      ? brand.gold.withValues(alpha: 0.2)
                                      : theme.dividerColor,
                              border: active
                                  ? Border.all(color: brand.gold, width: 2)
                                  : null,
                            ),
                            child: done
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : active
                                    ? Icon(Icons.circle, color: brand.gold, size: 10)
                                    : null,
                          ),
                          if (i < _steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: done ? brand.gold : theme.dividerColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _steps[i].substring(0, 1).toUpperCase() + _steps[i].substring(1),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                          color: active || done
                              ? brand.gold
                              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.order});
  final PreOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tracking Info',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(order.trackingId,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: order.trackingId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tracking ID copied')),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Placed on ${_formatDate(order.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.order});
  final PreOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(order.productName, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 6),
          _row('Qty', '${order.quantity}', theme),
          _row('Unit price', formatTaka(order.discountedPrice), theme),
          _row('Delivery', formatTaka(order.deliveryCharge), theme),
          const Divider(),
          _row('Total', formatTaka(order.total), theme, bold: true, color: brand.gold),
        ],
      ),
    );
  }

  Widget _row(String label, String value, ThemeData theme,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : null,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final PreOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.paymentMethod.toUpperCase(),
                  style: theme.textTheme.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.paymentStatus == 'paid'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.paymentStatus.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: order.paymentStatus == 'paid' ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
