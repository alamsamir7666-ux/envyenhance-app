import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../theme/app_brand_colors.dart';
import '../utils/formatters.dart';
import 'app_badge.dart';
import 'app_skeleton.dart';

/// Standard product card for grids (home sections, browse, search
/// results). Tapping navigates to the product detail screen.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onWishlistToggle,
    this.isWishlisted = false,
    super.key,
  });

  final Product product;
  final VoidCallback? onWishlistToggle;
  final bool isWishlisted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return Semantics(
      button: true,
      label: '${product.name}, ${formatTaka(product.effectivePrice)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/products/${product.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(url: product.primaryImage),
                    if (product.isOnSale)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: AppBadge.solid(
                          text:
                              '-${(((product.price - product.discountPrice!) / product.price) * 100).round()}%',
                          color: theme.colorScheme.error,
                        ),
                      ),
                    if (product.productStatus == 'pre_order')
                      Positioned(
                        top: 8,
                        left: 8,
                        child: AppBadge.solid(text: 'Pre-Order', color: brand.gold),
                      )
                    else if (!product.inStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: AppBadge.solid(text: 'Sold out', color: brand.textSecondary),
                      ),
                    if (onWishlistToggle != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? theme.colorScheme.error : Colors.white,
                          ),
                          style: IconButton.styleFrom(backgroundColor: Colors.black26),
                          onPressed: onWishlistToggle,
                          tooltip: isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    if (product.reviewCount > 0)
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: brand.gold),
                          const SizedBox(width: 2),
                          Text(
                            '${product.averageRating} (${product.reviewCount})',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatTaka(product.effectivePrice),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: brand.gold,
                          ),
                        ),
                        if (product.isOnSale) ...[
                          const SizedBox(width: 6),
                          Text(
                            formatTaka(product.price),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
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
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    if (url.isEmpty) {
      return Container(
        color: brand.roseSurface,
        child: Icon(Icons.image_not_supported_outlined, color: brand.textSecondary),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => const AppShimmer(child: ColoredBox(color: Colors.white)),
      errorWidget: (context, _, __) => Container(
        color: brand.roseSurface,
        child: Icon(Icons.broken_image_outlined, color: brand.textSecondary),
      ),
    );
  }
}
