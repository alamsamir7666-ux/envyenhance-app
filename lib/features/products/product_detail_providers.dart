import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/product.dart';
import '../../core/providers.dart';

final productDetailProvider =
    FutureProvider.family<Product, int>((ref, productId) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getById(productId);
});
