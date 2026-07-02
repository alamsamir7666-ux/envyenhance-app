import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/wishlist_loyalty.dart';
import '../../core/providers.dart';

class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  @override
  Future<List<WishlistItem>> build() async {
    final repo = ref.read(wishlistRepositoryProvider);
    try {
      return await repo.getWishlist();
    } on ApiException catch (e) {
      if (e.statusCode == 401) return [];
      rethrow;
    }
  }

  Future<void> toggle(int productId) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final current = state.valueOrNull ?? [];
    final isWishlisted = current.any((i) => i.productId == productId);

    state = const AsyncLoading<List<WishlistItem>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      if (isWishlisted) {
        await repo.remove(productId);
      } else {
        await repo.add(productId);
      }
      return repo.getWishlist();
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<WishlistItem>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => ref.read(wishlistRepositoryProvider).getWishlist());
  }
}

final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>(WishlistNotifier.new);

/// Just the set of wishlisted product IDs — cheap to watch from product
/// cards without depending on the full wishlist item list.
final wishlistProductIdsProvider = Provider<Set<int>>((ref) {
  final wishlist = ref.watch(wishlistProvider);
  return wishlist.maybeWhen(
    data: (items) => items.map((i) => i.productId).toSet(),
    orElse: () => {},
  );
});
