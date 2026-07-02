import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Standard product card for grids (home sections, browse, search results).
/// Tapping navigates to the product detail screen.
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
    return Semantics(
      button: true,
      label: '${product.name}, ${formatTaka(product.effectivePrice)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/products/${product.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
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
                        child: _Badge(
                          text:
                              '-${(((product.price - product.discountPrice!) / product.price) * 100).round()}%',
                          color: AppColors.error,
                        ),
                      ),
                    if (!product.inStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(text: 'Sold out', color: AppColors.textSecondary),
                      ),
                    if (onWishlistToggle != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? AppColors.error : Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black26,
                          ),
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    if (product.reviewCount > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.accent),
                          const SizedBox(width: 2),
                          Text(
                            '${product.averageRating} (${product.reviewCount})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatTaka(product.effectivePrice),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                        ),
                        if (product.isOnSale) ...[
                          const SizedBox(width: 6),
                          Text(
                            formatTaka(product.price),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    if (url.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.primaryLight,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, _, __) => Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
