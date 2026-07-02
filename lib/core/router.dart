import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_service.dart';
import 'providers.dart';
import 'widgets/app_shell.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_screen.dart';
import '../features/products/product_list_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/wishlist/wishlist_screen.dart';
import '../features/loyalty/loyalty_screen.dart';
import '../features/profile/profile_screen.dart';

/// Routes that require a signed-in user. Anything not in this list is
/// accessible to guests (browsing products, viewing product details).
const _protectedRoutes = [
  '/cart',
  '/checkout',
  '/orders',
  '/wishlist',
  '/loyalty',
  '/profile',
];

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final isProtected =
          _protectedRoutes.any((p) => state.matchedLocation.startsWith(p));
      final signedIn = auth.isSignedIn;

      if (isProtected && !signedIn) {
        return '/sign-in?redirect=${Uri.encodeComponent(state.matchedLocation)}';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/products',
            builder: (context, state) => ProductListScreen(
              category: state.uri.queryParameters['category'],
              search: state.uri.queryParameters['search'],
            ),
          ),
          GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),
          GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailScreen(
          orderId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/loyalty', builder: (context, state) => const LoyaltyScreen()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
    ],
  );
});
