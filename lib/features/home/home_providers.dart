import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/products_repository.dart';
import '../../core/models/misc.dart';
import '../../core/providers.dart';

final homepageSectionsProvider = FutureProvider<HomepageSections>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.homepage();
});

final homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.list();
});
