import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/api_client.dart';
import 'api/cart_repository.dart';
import 'api/loyalty_repository.dart';
import 'api/misc_repository.dart';
import 'api/orders_repository.dart';
import 'api/products_repository.dart';
import 'api/reviews_repository.dart';
import 'api/wishlist_repository.dart';
import 'auth/auth_service.dart';

/// The single AuthService instance for the app. Overridden with a real
/// implementation in main.dart.
///
/// This is a ChangeNotifierProvider (not a plain Provider) specifically so
/// that any provider which does `ref.watch(authServiceProvider)` — rather
/// than `ref.read(...)` — automatically rebuilds whenever sign-in/sign-out
/// fires `notifyListeners()`. This is what makes user-specific providers
/// (profile, orders, cart, loyalty) correctly refetch instead of serving
/// stale data cached from a previous user's session. See
/// `authIdentityProvider` below for the piece that ties them together.
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  throw UnimplementedError('authServiceProvider must be overridden in main.dart');
});

/// A minimal, comparable snapshot of "who is currently signed in."
///
/// Providers that fetch user-specific data should watch *this* (not
/// authServiceProvider directly) as their invalidation trigger: Riverpod
/// only rebuilds a provider when the watched value actually changes by
/// equality, and this record's identity changes exactly when the signed-in
/// user changes (including signing out, which produces a distinct "no one
/// signed in" value) — never on unrelated notifyListeners() calls that
/// don't affect identity.
typedef AuthIdentity = ({bool isSignedIn, String? userId});

final authIdentityProvider = Provider<AuthIdentity>((ref) {
  final auth = ref.watch(authServiceProvider);
  return (isSignedIn: auth.isSignedIn, userId: auth.userId);
});

/// The shared Dio-based API client. Automatically attaches the current
/// session token (if signed in) to every request via authServiceProvider.
final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authServiceProvider);
  return ApiClient(tokenProvider: auth.getToken);
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(apiClientProvider));
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(apiClientProvider));
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(apiClientProvider));
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(apiClientProvider));
});

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  return LoyaltyRepository(ref.watch(apiClientProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(apiClientProvider));
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(apiClientProvider));
});
