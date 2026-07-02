import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/misc.dart';
import '../../core/models/product.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/product_card.dart';
import '../wishlist/wishlist_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homepage = ref.watch(homepageSectionsProvider);
    final categories = ref.watch(homeCategoriesProvider);
    final wishlistIds = ref.watch(wishlistProductIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EnvyEnhance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push('/products'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(homepageSectionsProvider);
          ref.invalidate(homeCategoriesProvider);
          await ref.read(homepageSectionsProvider.future);
        },
        child: homepage.when(
          loading: () => const LoadingView(message: 'Loading products…'),
          error: (err, _) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.invalidate(homepageSectionsProvider),
          ),
          data: (sections) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _HeroBanner(),
                categories.when(
                  loading: () => const SizedBox(height: 90, child: LoadingView()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cats) => _CategoryRow(categories: cats),
                ),
                if (sections.trending.isNotEmpty)
                  _ProductSection(
                    title: 'Trending Now',
                    products: sections.trending,
                    wishlistIds: wishlistIds,
                  ),
                if (sections.newArrivals.isNotEmpty)
                  _ProductSection(
                    title: 'New Arrivals',
                    products: sections.newArrivals,
                    wishlistIds: wishlistIds,
                  ),
                if (sections.trending.isEmpty && sections.newArrivals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyView(
                      icon: Icons.spa_outlined,
                      title: 'No products yet',
                      subtitle: 'Check back soon for new arrivals.',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8F4460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Glow from within',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Discover skincare made for you',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            onPressed: () => context.push('/products'),
            child: const Text('Shop Now'),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.categories});
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/products?category=${cat.slug}'),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: cat.image != null && cat.image!.isNotEmpty
                        ? NetworkImage(cat.image!)
                        : null,
                    child: cat.image == null || cat.image!.isEmpty
                        ? const Icon(Icons.spa_outlined, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.title,
    required this.products,
    required this.wishlistIds,
  });

  final String title;
  final List<Product> products;
  final Set<int> wishlistIds;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final product = products[i];
                return SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: product,
                    isWishlisted: wishlistIds.contains(product.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
