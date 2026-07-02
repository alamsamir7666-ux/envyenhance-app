import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/product.dart';
import '../../core/providers.dart';

@immutable
class ProductListState {
  const ProductListState({
    this.products = const [],
    this.category,
    this.search,
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
  });

  final List<Product> products;
  final String? category;
  final String? search;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  ProductListState copyWith({
    List<Product>? products,
    String? category,
    bool clearCategory = false,
    String? search,
    bool clearSearch = false,
    int? page,
    bool? hasMore,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      category: clearCategory ? null : (category ?? this.category),
      search: clearSearch ? null : (search ?? this.search),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProductListNotifier extends Notifier<ProductListState> {
  @override
  ProductListState build() => const ProductListState();

  Future<void> setFilters({String? category, String? search}) async {
    state = ProductListState(category: category, search: search, isLoading: true);
    await _load(page: 1);
  }

  Future<void> refresh() => _load(page: 1);

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await _load(page: state.page + 1, append: true);
  }

  Future<void> _load({required int page, bool append = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(productsRepositoryProvider);
    try {
      final result = await repo.listProducts(
        category: state.category,
        search: state.search,
        page: page,
      );
      state = state.copyWith(
        products: append ? [...state.products, ...result.products] : result.products,
        page: result.page,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
    }
  }
}

final productListProvider =
    NotifierProvider<ProductListNotifier, ProductListState>(ProductListNotifier.new);
