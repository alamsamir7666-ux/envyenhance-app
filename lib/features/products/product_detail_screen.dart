import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/product.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../cart/cart_providers.dart';
import '../reviews/review_widgets.dart';
import '../wishlist/wishlist_providers.dart';
import 'product_detail_providers.dart';
import 'product_qa_widgets.dart';
import 'stock_alert_button.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});
  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imageIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlistIds = ref.watch(wishlistProductIdsProvider);
    final isWishlisted = wishlistIds.contains(widget.productId);
    final theme = Theme.of(context);
    final brand = context.brand;

    return Scaffold(
      body: productAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 340,
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: theme.colorScheme.onSurface,
                actions: [
                  IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? theme.colorScheme.error : null,
                    ),
                    onPressed: () => ref.read(wishlistProvider.notifier).toggle(product.id),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ImageCarousel(
                    images: product.images,
                    currentIndex: _imageIndex,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.category.toUpperCase(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: brand.gold,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              )),
                      const SizedBox(height: 4),
                      // The one serif moment for this screen, per the
                      // design plan — the product name itself.
                      Text(product.name, style: theme.textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, size: 18, color: brand.gold),
                          const SizedBox(width: 4),
                          Text('${product.averageRating}', style: theme.textTheme.bodyLarge),
                          const SizedBox(width: 4),
                          Text('(${product.reviewCount} reviews)', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatTaka(product.effectivePrice),
                            style: theme.textTheme.headlineMedium?.copyWith(color: brand.gold),
                          ),
                          if (product.isOnSale) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                formatTaka(product.price),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.productStatus == 'pre_order'
                            ? 'Available for Pre-Order'
                            : product.inStock
                                ? 'In stock (${product.stock} left)'
                                : 'Out of stock',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: product.productStatus == 'pre_order'
                                  ? brand.gold
                                  : product.inStock
                                      ? brand.sage
                                      : theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (!product.inStock) ...[
                        const SizedBox(height: 12),
                        StockAlertButton(productId: product.id),
                      ],
                      const Divider(height: 32),
                      Text('Description', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(product.description, style: theme.textTheme.bodyLarge),
                      if (product.keyBenefits.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Key Benefits', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 10),
                        // Soft rose chips per the design plan, rather than
                        // a plain checkmark list.
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final b in product.keyBenefits)
                              Chip(label: Text(b)),
                          ],
                        ),
                      ],
                      if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Ingredients', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(product.ingredients!, style: theme.textTheme.bodyLarge),
                      ],
                      const Divider(height: 32),
                      ProductReviewsSection(productId: product.id),
                      const Divider(height: 32),
                      ProductQASection(productId: product.id),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => _AddToCartBar(
          product: product,
          quantity: _quantity,
          onQuantityChanged: (q) => setState(() => _quantity = q),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    if (images.isEmpty) {
      return Container(
        color: brand.roseSurface,
        child: Icon(Icons.image_not_supported_outlined, size: 64, color: brand.textSecondary),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, i) => CachedNetworkImage(
            imageUrl: images[i],
            fit: BoxFit.cover,
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < images.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == currentIndex ? Colors.white : Colors.white38,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddToCartBar extends ConsumerWidget {
  const _AddToCartBar({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final isAdding = cartState.isLoading;
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            _QuantityStepper(
              quantity: quantity,
              max: product.stock,
              onChanged: onQuantityChanged,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: !product.inStock || isAdding
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(cartProvider.notifier)
                              .addItem(product.id, quantity: quantity);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                child: isAdding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(product.productStatus == 'pre_order' ? 'Pre-Order Now' : product.inStock ? 'Add to Cart' : 'Out of Stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.max,
    required this.onChanged,
  });

  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          Text('$quantity', style: Theme.of(context).textTheme.bodyLarge),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}
