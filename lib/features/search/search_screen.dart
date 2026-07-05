import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/search_repository.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<SearchResult>((ref) async {
  final q = ref.watch(_searchQueryProvider);
  if (q.trim().length < 2) return SearchResult(products: [], categories: []);
  await Future.delayed(const Duration(milliseconds: 300)); // debounce
  return ref.watch(searchRepositoryProvider).autocomplete(q);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref.read(_searchQueryProvider.notifier).state = value;
  }

  void _onSubmit(String value) {
    if (value.trim().isNotEmpty) {
      context.push('/products?search=${Uri.encodeComponent(value.trim())}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: _onSubmit,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(_searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.trim().length < 2
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('Type to search products', style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Search failed: $e')),
              data: (results) {
                if (results.products.isEmpty && results.categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text('No results for "$query"', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _onSubmit(query),
                          child: const Text('Browse all products'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  children: [
                    // Categories
                    if (results.categories.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('CATEGORIES',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brand.gold,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      for (final cat in results.categories)
                        ListTile(
                          leading: const Icon(Icons.category_outlined),
                          title: Text(cat.name),
                          onTap: () => context.push('/products?category=${cat.slug}'),
                        ),
                      const Divider(),
                    ],

                    // Products
                    if (results.products.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text('PRODUCTS',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brand.gold,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      for (final product in results.products)
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product.image != null
                                ? CachedNetworkImage(
                                    imageUrl: product.image!,
                                    width: 48, height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48, height: 48,
                                    color: brand.roseSurface,
                                  ),
                          ),
                          title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(formatTaka(product.effectivePrice)),
                          onTap: () => context.push('/products/${product.id}'),
                        ),

                      // See all results
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton(
                          onPressed: () => _onSubmit(query),
                          child: Text('See all results for "$query"'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
