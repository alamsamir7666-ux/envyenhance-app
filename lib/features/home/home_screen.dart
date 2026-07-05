import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/misc.dart';
import '../../core/models/product.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/section_header.dart';
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
        color: context.brand.gold,
        onRefresh: () async {
          ref.invalidate(homepageSectionsProvider);
          ref.invalidate(homeCategoriesProvider);
          ref.invalidate(bestProductsByTagProvider);
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
                const _HeroBanner(),
                categories.when(
                  loading: () => const SizedBox(height: 110, child: LoadingView()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cats) => _CategoryRow(categories: cats),
                ),
                const SizedBox(height: 12),
                _FeaturedTabsSection(
                  trending: sections.trending,
                  newArrivals: sections.newArrivals,
                  wishlistIds: wishlistIds,
                ),
                const SizedBox(height: 8),
                _BestByCategorySection(wishlistIds: wishlistIds),
                const SizedBox(height: 8),
                const _WhyChooseUsSection(),
                if (sections.trending.isEmpty && sections.newArrivals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
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

/// Hero — mirrors the website's "Glow with purpose." headline treatment,
/// adapted to a compact native card rather than a full-bleed section.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF23201C), const Color(0xFF3A2B2E)]
              : [const Color(0xFF2E2724), const Color(0xFF4A3630)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Glow with',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 34,
              height: 1.05,
            ),
          ),
          Text(
            'purpose.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: brand.gold,
              fontSize: 34,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Authentic Japanese skincare, made for you',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2E2724),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            ),
            onPressed: () => context.push('/products'),
            child: const Text('Shop All'),
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
    final brand = context.brand;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final cat = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/products?category=${cat.slug}'),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: brand.roseSurface,
                    backgroundImage: cat.image != null && cat.image!.isNotEmpty
                        ? NetworkImage(cat.image!)
                        : null,
                    child: cat.image == null || cat.image!.isEmpty
                        ? Icon(Icons.spa_outlined, color: brand.roseText)
                        : null,
                  ),
                  const SizedBox(height: 8),
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

/// "Discover Your J-Beauty Glow" section — Trending / New Arrivals pill
/// tabs, matching the website's activeTab toggle exactly.
class _FeaturedTabsSection extends ConsumerStatefulWidget {
  const _FeaturedTabsSection({
    required this.trending,
    required this.newArrivals,
    required this.wishlistIds,
  });

  final List<Product> trending;
  final List<Product> newArrivals;
  final Set<int> wishlistIds;

  @override
  ConsumerState<_FeaturedTabsSection> createState() => _FeaturedTabsSectionState();
}

class _FeaturedTabsSectionState extends ConsumerState<_FeaturedTabsSection> {
  bool _showTrending = true;

  @override
  Widget build(BuildContext context) {
    final products = _showTrending ? widget.trending : widget.newArrivals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Discover Your J-Beauty Glow',
          onSeeAll: () => context.push('/products'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Pill(
                label: 'Trending',
                selected: _showTrending,
                onTap: () => setState(() => _showTrending = true),
              ),
              const SizedBox(width: 8),
              _Pill(
                label: 'New Arrivals',
                selected: !_showTrending,
                onTap: () => setState(() => _showTrending = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No products here yet. Check back soon!')),
          )
        else
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
                    isWishlisted: widget.wishlistIds.contains(product.id),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// "Best J-Beauty Products" section — category pill tabs (Skin/Hair/
/// Make Up/Body Care), matching the website's BEST_TABS exactly.
class _BestByCategorySection extends ConsumerWidget {
  const _BestByCategorySection({required this.wishlistIds});
  final Set<int> wishlistIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedBestTabProvider);
    final productsAsync = ref.watch(bestProductsByTagProvider(selectedTab));
    final theme = Theme.of(context);
    final brand = context.brand;

    return Container(
      color: brand.roseSurface.withValues(alpha: 0.25),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'BASED ON CATEGORY',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: brand.gold,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          SectionHeader(
            title: 'Best J-Beauty Products',
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            onSeeAll: () => context.push('/products'),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: BestProductsTab.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final tab = BestProductsTab.values[i];
                return _Pill(
                  label: tab.label,
                  selected: tab == selectedTab,
                  onTap: () => ref.read(selectedBestTabProvider.notifier).state = tab,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          productsAsync.when(
            loading: () => const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 80,
              child: Center(child: Text('Could not load this category right now.')),
            ),
            data: (products) {
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No products here yet. Check back soon!')),
                );
              }
              return SizedBox(
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? brand.gold : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? brand.gold : theme.dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// "Our Promise to You" — mirrors the website's three-column trust
/// section (Genuine Japanese Brands / Fair Pricing / Responsible Delivery).
class _WhyChooseUsSection extends StatelessWidget {
  const _WhyChooseUsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    const items = [
      (
        icon: Icons.verified_outlined,
        title: 'Genuine Japanese Brands',
        desc: 'Every product is sourced directly from trusted Japanese brands — real, verified, authentic.',
      ),
      (
        icon: Icons.shield_outlined,
        title: 'Fair & Honest Pricing',
        desc: 'No markup gimmicks. Fair, affordable prices without compromising on authenticity.',
      ),
      (
        icon: Icons.volunteer_activism_outlined,
        title: 'Delivered with Responsibility',
        desc: 'We take full responsibility for delivering authenticity to your doorstep.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Text(
            'WHY CHOOSE US',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: brand.gold,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text('Our Promise to You', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 28),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: brand.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: brand.gold, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.desc,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
