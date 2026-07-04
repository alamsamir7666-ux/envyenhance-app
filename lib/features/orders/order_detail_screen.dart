import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/async_states.dart';
import '../returns/returns_screen.dart';
import 'orders_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});
  final int orderId;

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep order')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel order', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(orderId);
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(myOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    final brand = context.brand;
    switch (status) {
      case 'delivered':
        return brand.sage;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return brand.gold;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final theme = Theme.of(context);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) {
          final statusColor = _statusColor(context, order.orderStatus);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${order.trackingId}', style: theme.textTheme.displaySmall),
                        const SizedBox(height: 6),
                        Text(formatDate(order.createdAt), style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  AppBadge.soft(
                    text: order.orderStatus.toUpperCase(),
                    color: statusColor,
                    textColor: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Payment: ${order.paymentMethod.toUpperCase()} · ${order.paymentStatus}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Text('Items', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (int i = 0; i < order.items.length; i++) ...[
                      _OrderItemTile(item: order.items[i]),
                      if (i != order.items.length - 1) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: theme.dividerColor),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Shipping Address', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.shippingAddress.fullName,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(order.shippingAddress.phone, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${order.shippingAddress.street}, ${order.shippingAddress.city}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: brand.roseSurface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (order.discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount', style: theme.textTheme.bodyLarge),
                          Text('-${formatTaka(order.discountAmount)}', style: TextStyle(color: brand.sage)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: theme.dividerColor),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: theme.textTheme.headlineMedium),
                        Text(
                          formatTaka(order.totalAmount),
                          style: theme.textTheme.headlineMedium?.copyWith(color: brand.gold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (order.canCancel) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _confirmCancel(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: const Text('Cancel Order'),
                  ),
                ),
              ],
              if (order.orderStatus == 'delivered') ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showRequestReturnDialog(context, ref, orderId: order.id),
                    child: const Text('Request a Return'),
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

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            item.productImage,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 64,
              height: 64,
              color: brand.roseSurface,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text('Qty: ${item.quantity}', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        Text(
          formatTaka(item.price * item.quantity),
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
