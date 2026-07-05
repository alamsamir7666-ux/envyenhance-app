import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';

final _trackQueryProvider = StateProvider<String>((ref) => '');

final trackOrderProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, trackingId) async {
  return ref.watch(ordersRepositoryProvider).trackByTrackingId(trackingId);
});

const _orderSteps = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];

class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key, this.initialTrackingId});
  final String? initialTrackingId;

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  late final TextEditingController _ctrl;
  String _submitted = '';

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTrackingId ?? '');
    if (widget.initialTrackingId != null) {
      _submitted = widget.initialTrackingId!;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _track() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    // Pre-order tracking IDs start with PRE-
    if (v.toUpperCase().startsWith('PRE-')) {
      context.push('/pre-orders/${v.toUpperCase()}');
      return;
    }
    setState(() => _submitted = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter your tracking ID',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onSubmitted: (_) => _track(),
                        decoration: InputDecoration(
                          hintText: 'e.g. EE-XXXXXXXX or PRE-XXXXXX',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _track,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Track'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_submitted.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TrackResult(trackingId: _submitted),
          ],
        ],
      ),
    );
  }
}

class _TrackResult extends ConsumerWidget {
  const _TrackResult({required this.trackingId});
  final String trackingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final orderAsync = ref.watch(trackOrderProvider(trackingId));

    return orderAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Order not found. Please check your tracking ID.'),
            ),
          ],
        ),
      ),
      data: (order) {
        final currentStep = _orderSteps.indexOf(order.orderStatus ?? '');
        final isCancelled = order.orderStatus == 'cancelled';

        return Column(
          children: [
            // Status stepper
            Container(
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
                      Text(
                        'Order #${order.trackingId}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? theme.colorScheme.error.withValues(alpha: 0.1)
                              : brand.sage.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (order.orderStatus ?? '').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCancelled
                                ? theme.colorScheme.error
                                : brand.sage,
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
                        color:
                            theme.colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('This order has been cancelled.'),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: List.generate(_orderSteps.length, (i) {
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
                                        color: done || active
                                            ? brand.gold
                                            : theme.dividerColor,
                                      ),
                                    ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: done
                                          ? brand.gold
                                          : active
                                              ? brand.gold.withValues(alpha: 0.2)
                                              : theme.dividerColor,
                                      border: active
                                          ? Border.all(
                                              color: brand.gold, width: 2)
                                          : null,
                                    ),
                                    child: done
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  if (i < _orderSteps.length - 1)
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: done
                                            ? brand.gold
                                            : theme.dividerColor,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _orderSteps[i][0].toUpperCase() +
                                    _orderSteps[i].substring(1),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: active || done
                                      ? brand.gold
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
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
            ),

            // Items
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items Ordered',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(item.productName,
                                  style: theme.textTheme.bodyMedium),
                            ),
                            Text(
                              'x${item.quantity} · ${formatTaka(item.price * item.quantity)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(formatTaka(order.totalAmount),
                            style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: brand.gold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
