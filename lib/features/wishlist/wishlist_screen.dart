import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../cart/cart_providers.dart';
import 'wishlist_providers.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final theme = Theme.of(context);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: wishlistAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.read(wishlistProvider.notifier).refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              subtitle: 'Save products you love for later.',
              actionLabel: 'Browse Products',
              onAction: () => context.go('/products'),
            );
          }
          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () => ref.read(wishlistProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/products/${item.productId}'),
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: item.product.primaryImage,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: brand.roseSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTaka(item.product.effectivePrice),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                      color: brand.gold,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          tooltip: 'Add to cart',
                          onPressed: item.product.stock > 0
                              ? () => ref.read(cartProvider.notifier).addItem(item.productId)
                              : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.favorite, color: theme.colorScheme.error),
                          tooltip: 'Remove from wishlist',
                          onPressed: () => ref.read(wishlistProvider.notifier).toggle(item.productId),
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
}
