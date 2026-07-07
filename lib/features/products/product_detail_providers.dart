import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/product.dart';
import '../../core/models/variant.dart';
import '../../core/providers.dart';

final productDetailProvider =
    FutureProvider.family<Product, int>((ref, productId) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getById(productId);
});

/// Variants (size/shade/pack) for a product. Empty list if the product
/// has none — the UI treats that as "no selector to show", not an error.
final productVariantsProvider =
    FutureProvider.family<List<ProductVariant>, int>((ref, productId) async {
  final repo = ref.watch(variantsRepositoryProvider);
  return repo.getVariants(productId);
});

/// "You Might Also Like" — reuses the existing category listing endpoint
/// rather than requiring a dedicated backend "related products" route.
/// Excludes the current product and caps the result to a small row.
final relatedProductsProvider =
    FutureProvider.family<List<Product>, Product>((ref, product) async {
  final repo = ref.watch(productsRepositoryProvider);
  final page = await repo.listProducts(category: product.category, limit: 10);
  return page.products.where((p) => p.id != product.id).take(8).toList();
});
