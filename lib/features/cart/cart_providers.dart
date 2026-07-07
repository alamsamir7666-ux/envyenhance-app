import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/cart.dart';
import '../../core/providers.dart';

/// Holds the cart as an AsyncValue so every screen gets consistent
/// loading/error/data handling. Refetches from the server after every
/// mutation (add/update/remove) since the backend recalculates
/// subtotal/discount/total server-side — trusting a client-side
/// recomputation would drift from coupon/discount logic on the backend.
class CartNotifier extends AsyncNotifier<Cart> {
  @override
  Future<Cart> build() async {
    // Watching authIdentityProvider here means this whole notifier is
    // torn down and rebuilt from scratch whenever the signed-in user
    // changes, so a freshly-fetched cart always replaces any cart data
    // left over from a previous session.
    ref.watch(authIdentityProvider);
    return _fetch();
  }

  Future<Cart> _fetch() async {
    final repo = ref.read(cartRepositoryProvider);
    try {
      return await repo.getCart();
    } on ApiException catch (e) {
      // A signed-out user hitting a protected cart route shouldn't crash
      // the provider — surface an empty cart instead of an error state,
      // since the router already redirects unauthenticated users away
      // from /cart before this would matter in practice.
      if (e.statusCode == 401) return Cart.empty();
      rethrow;
    }
  }

  Future<void> addItem(int productId, {int quantity = 1, int? variantId}) async {
    final repo = ref.read(cartRepositoryProvider);
    state = const AsyncLoading<Cart>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => repo.addItem(productId, quantity, variantId: variantId),
    );
  }

  Future<void> updateQuantity(int productId, int quantity, {int? variantId}) async {
    final repo = ref.read(cartRepositoryProvider);
    state = const AsyncLoading<Cart>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => repo.updateQuantity(productId, quantity, variantId: variantId),
    );
  }

  Future<void> removeItem(int productId, {int? variantId}) async {
    final repo = ref.read(cartRepositoryProvider);
    state = const AsyncLoading<Cart>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => repo.removeItem(productId, variantId: variantId),
    );
  }

  Future<void> clear() async {
    final repo = ref.read(cartRepositoryProvider);
    state = const AsyncLoading<Cart>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await repo.clearCart();
      return Cart.empty();
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Cart>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(CartNotifier.new);

/// Convenience provider for the bottom-nav badge — doesn't rebuild the
/// whole cart screen when only the count is needed.
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.maybeWhen(data: (c) => c.itemCount, orElse: () => 0);
});
