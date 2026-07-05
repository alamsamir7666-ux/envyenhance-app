import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/products_repository.dart';
import '../../core/models/misc.dart';
import '../../core/models/product.dart';
import '../../core/providers.dart';

final homepageSectionsProvider = FutureProvider<HomepageSections>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.homepage();
});

final homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.list();
});

/// The four "Best J-Beauty Products" tabs on the website's home page —
/// mirrors `BEST_TABS` in HomePage.tsx exactly (same tag values and
/// labels) so the app surfaces the same curated homepage merchandising
/// the admin sets up on the website.
enum BestProductsTab {
  skinCare('best_skin_care', 'SKIN CARE'),
  hairCare('best_hair_care', 'HAIR CARE'),
  makeUp('best_make_up', 'MAKE UP'),
  bodyCare('best_body_care', 'BODY CARE');

  const BestProductsTab(this.tag, this.label);
  final String tag;
  final String label;
}

final selectedBestTabProvider = StateProvider<BestProductsTab>((ref) => BestProductsTab.skinCare);

final bestProductsByTagProvider =
    FutureProvider.family<List<Product>, BestProductsTab>((ref, tab) async {
  final repo = ref.watch(productsRepositoryProvider);
  final page = await repo.listProducts(homepageTag: tab.tag, limit: 15);
  return page.products;
});

