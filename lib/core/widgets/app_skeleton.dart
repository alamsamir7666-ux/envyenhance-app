import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_brand_colors.dart';

/// Base shimmer wrapper, theme-aware (adapts base/highlight colors for
/// dark mode automatically). Wrap any skeleton shape in this instead of
/// hand-rolling Shimmer.fromColors per screen.
class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A241F) : const Color(0xFFEDE4DA);
    final highlight = isDark ? const Color(0xFF3A322B) : Colors.white;
    return Shimmer.fromColors(baseColor: base, highlightColor: highlight, child: child);
  }
}

/// A single skeleton block — rounded rectangle placeholder for images,
/// text lines, avatars, etc.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.borderRadius = 6,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton placeholder matching ProductCard's layout — used in grids
/// while product data is loading, so the loading state doesn't jump/
/// reflow once real content arrives.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return AppShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brand.roseSurface),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: SkeletonBox(borderRadius: 0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 100, height: 13),
                  SizedBox(height: 6),
                  SkeletonBox(width: 60, height: 11),
                  SizedBox(height: 8),
                  SkeletonBox(width: 70, height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of product-card skeletons, drop-in replacement for a product
/// grid while its provider is loading.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({this.count = 6, super.key});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (context, _) => const ProductCardSkeleton(),
    );
  }
}
