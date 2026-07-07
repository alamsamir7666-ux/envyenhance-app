import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/product.dart';
import '../../core/models/variant.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/staggered_entrance.dart';
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
  ProductVariant? _selectedVariant;

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
                    productId: product.id,
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
                      if (product.productStatus != 'pre_order' && !product.inStock) ...[
                        const SizedBox(height: 12),
                        StockAlertButton(productId: product.id),
                      ],
                      _VariantSelector(
                        productId: product.id,
                        selected: _selectedVariant,
                        onSelected: (v) => setState(() => _selectedVariant = v),
                      ),
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
              SliverToBoxAdapter(
                child: _RelatedProductsSection(product: product),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => _AddToCartBar(
          product: product,
          quantity: _quantity,
          variant: _selectedVariant,
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
    required this.productId,
  });

  final List<String> images;
  final int productId;
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
          itemBuilder: (context, i) => i == 0
              ? Hero(
                  tag: 'product-image-${productId}',
                  child: CachedNetworkImage(
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                  ),
                )
              : CachedNetworkImage(
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

/// Variant (size/shade/pack) selector shown on the product detail page.
/// Loads variants for the product and renders them as choice chips,
/// grouped by variantType. Selecting a chip updates price/stock shown
/// in the add-to-cart bar via the [onSelected] callback.
///
/// Renders nothing if the product has no variants, so this is safe to
/// place unconditionally in the layout for every product.
class _VariantSelector extends ConsumerWidget {
  const _VariantSelector({
    required this.productId,
    required this.selected,
    required this.onSelected,
  });

  final int productId;
  final ProductVariant? selected;
  final ValueChanged<ProductVariant?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variantsAsync = ref.watch(productVariantsProvider(productId));
    final theme = Theme.of(context);
    final brand = context.brand;

    return variantsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (variants) {
        if (variants.isEmpty) return const SizedBox.shrink();

        // Auto-select a sensible default once variants load, preferring
        // the first in-stock option so the add-to-cart button isn't
        // disabled on first render for no reason.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selected == null) {
            final firstInStock = variants.where((v) => v.inStock).toList();
            onSelected(firstInStock.isNotEmpty ? firstInStock.first : variants.first);
          }
        });

        // Group by variantType ("size", "shade", "pack"...) so each row
        // of chips represents one dimension of choice, matching how
        // most e-commerce PDPs present variants.
        final byType = <String, List<ProductVariant>>{};
        for (final v in variants) {
          byType.putIfAbsent(v.variantType, () => []).add(v);
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in byType.entries) ...[
                Text(
                  _labelForVariantType(entry.key),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in entry.value)
                      ChoiceChip(
                        label: Text(v.name),
                        selected: selected?.id == v.id,
                        onSelected: v.inStock ? (_) => onSelected(v) : null,
                        disabledColor: theme.disabledColor.withValues(alpha: 0.08),
                        labelStyle: TextStyle(
                          color: !v.inStock
                              ? theme.disabledColor
                              : selected?.id == v.id
                                  ? Colors.white
                                  : null,
                          decoration: !v.inStock ? TextDecoration.lineThrough : null,
                        ),
                        selectedColor: brand.gold,
                        backgroundColor: theme.cardTheme.color,
                        side: BorderSide(color: theme.dividerColor),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  String _labelForVariantType(String variantType) {
    switch (variantType) {
      case 'size':
        return 'Size';
      case 'shade':
        return 'Shade';
      case 'pack':
        return 'Pack';
      default:
        return variantType[0].toUpperCase() + variantType.substring(1);
    }
  }
}

/// "You Might Also Like" — horizontal row of same-category products,
/// shown beneath reviews/Q&A on the product detail screen.
class _RelatedProductsSection extends ConsumerWidget {
  const _RelatedProductsSection({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedProductsProvider(product));
    final wishlistIds = ref.watch(wishlistProductIdsProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final theme = Theme.of(context);

    return relatedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (related) {
        if (related.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('You Might Also Like', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: related.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final relatedProduct = related[i];
                    return SizedBox(
                      width: 160,
                      child: StaggeredEntrance(
                        index: i,
                        child: ProductCard(
                          product: relatedProduct,
                          isWishlisted: wishlistIds.contains(relatedProduct.id),
                          onWishlistToggle: () =>
                              wishlistNotifier.toggle(relatedProduct.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddToCartBar extends ConsumerStatefulWidget {
  const _AddToCartBar({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    this.variant,
  });

  final Product product;
  final int quantity;
  final ProductVariant? variant;
  final ValueChanged<int> onQuantityChanged;

  @override
  ConsumerState<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<_AddToCartBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _justAdded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playBounce() async {
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isAdding = cartState.isLoading;
    final theme = Theme.of(context);
    final product = widget.product;
    final variant = widget.variant;
    final isPreOrder = product.productStatus == 'pre_order';
    // The variant's own stock overrides the base product's once one is
    // selected — a product can be "in stock" overall while the chosen
    // size/shade specifically is sold out. Pre-order items are always
    // actionable regardless of raw stock count (stock is naturally 0
    // until the shipment arrives) — matches the website's button logic.
    final effectiveStock = variant?.stock ?? product.stock;
    final effectiveInStock =
        isPreOrder || (variant != null ? variant.inStock : product.inStock);

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
              quantity: widget.quantity,
              max: effectiveStock,
              onChanged: widget.onQuantityChanged,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ScaleTransition(
                scale: _scale,
                child: ElevatedButton(
                  onPressed: !effectiveInStock || isAdding
                      ? null
                      : isPreOrder
                          ? () => context.push('/pre-order-checkout', extra: product)
                          : () async {
                          try {
                            await ref
                                .read(cartProvider.notifier)
                                .addItem(
                                  product.id,
                                  quantity: widget.quantity,
                                  variantId: variant?.id,
                                );
                            if (context.mounted) {
                              setState(() => _justAdded = true);
                              unawaited(_playBounce());
                              Future.delayed(const Duration(milliseconds: 1100), () {
                                if (mounted) setState(() => _justAdded = false);
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isAdding
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : _justAdded
                            ? const Row(
                                key: ValueKey('added'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Added'),
                                ],
                              )
                            : Text(
                                key: const ValueKey('label'),
                                product.productStatus == 'pre_order'
                                    ? 'Pre-Order Now'
                                    : effectiveInStock
                                        ? 'Add to Cart'
                                        : 'Out of Stock',
                              ),
                  ),
                ),
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
