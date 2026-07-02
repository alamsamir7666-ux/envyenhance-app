import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/product_card.dart';
import '../wishlist/wishlist_providers.dart';
import 'product_list_providers.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({this.category, this.search, super.key});

  final String? category;
  final String? search;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late final TextEditingController _searchController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.search ?? '');
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).setFilters(
            category: widget.category,
            search: widget.search,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final wishlistIds = ref.watch(wishlistProductIdsProvider);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search products…',
            prefixIcon: Icon(Icons.search, size: 20),
            border: InputBorder.none,
            isDense: true,
          ),
          onSubmitted: (value) {
            ref.read(productListProvider.notifier).setFilters(search: value);
          },
        ),
      ),
      body: Column(
        children: [
          if (state.category != null) _ActiveFilterChip(
            label: state.category!,
            onClear: () => ref.read(productListProvider.notifier).setFilters(category: null),
          ),
          Expanded(
            child: state.isLoading && state.products.isEmpty
                ? const LoadingView(message: 'Loading products…')
                : state.error != null && state.products.isEmpty
                    ? ErrorView(
                        message: state.error!,
                        onRetry: () => ref.read(productListProvider.notifier).refresh(),
                      )
                    : state.products.isEmpty
                        ? const EmptyView(
                            icon: Icons.search_off,
                            title: 'No products found',
                            subtitle: 'Try a different search or category.',
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => ref.read(productListProvider.notifier).refresh(),
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.62,
                              ),
                              itemCount: state.products.length + (state.hasMore ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i >= state.products.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                  );
                                }
                                final product = state.products[i];
                                return ProductCard(
                                  product: product,
                                  isWishlisted: wishlistIds.contains(product.id),
                                  onWishlistToggle: () => wishlistNotifier.toggle(product.id),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onClear});
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(label),
          onDeleted: onClear,
          backgroundColor: AppColors.primaryLight,
        ),
      ),
    );
  }
}
