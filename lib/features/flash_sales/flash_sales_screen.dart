import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/flash_sale.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';

final flashSalesProvider = FutureProvider<List<FlashSaleProduct>>((ref) async {
  return ref.watch(flashSalesRepositoryProvider).getFlashSales();
});

class FlashSalesScreen extends ConsumerWidget {
  const FlashSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashAsync = ref.watch(flashSalesProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.flash_on, color: brand.gold, size: 20),
            const SizedBox(width: 6),
            const Text('Flash Sales'),
          ],
        ),
      ),
      body: flashAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(flashSalesProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyView(
              icon: Icons.flash_off_outlined,
              title: 'No flash sales right now',
              subtitle: 'Check back soon for limited-time deals.',
            );
          }
          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () async => ref.invalidate(flashSalesProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) => _FlashProductCard(product: products[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FlashProductCard extends StatefulWidget {
  const _FlashProductCard({required this.product});
  final FlashSaleProduct product;

  @override
  State<_FlashProductCard> createState() => _FlashProductCardState();
}

class _FlashProductCardState extends State<_FlashProductCard> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    // Flash sales run until end of day by default
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _remaining = endOfDay.difference(now);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining -= const Duration(seconds: 1);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final product = widget.product;

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: product.primaryImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.primaryImage,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(color: brand.roseSurface),
                  ),
                  if (product.discountPercent > 0)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Countdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: brand.gold.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 12, color: brand.gold),
                  const SizedBox(width: 4),
                  Text(
                    '${_pad(_remaining.inHours)}:${_pad(_remaining.inMinutes % 60)}:${_pad(_remaining.inSeconds % 60)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: brand.gold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatTaka(product.effectivePrice),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: brand.gold,
                          fontSize: 14,
                        ),
                      ),
                      if (product.discountPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatTaka(product.price),
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
