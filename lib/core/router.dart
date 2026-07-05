import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers.dart';
import 'push/push_service.dart';
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
import '../features/gift_cards/gift_cards_screen.dart';
import '../features/subscriptions/subscriptions_screen.dart';
import '../features/subscriptions/subscription_detail_screen.dart';
import '../features/skin_profile/skin_quiz_screen.dart';
import '../features/referrals/referrals_screen.dart';
import '../features/blog/blog_list_screen.dart';
import '../features/blog/blog_article_screen.dart';
import '../features/pre_orders/pre_orders_screen.dart';
import '../features/returns/returns_screen.dart';
import '../features/addresses/addresses_screen.dart';
import '../features/flash_sales/flash_sales_screen.dart';
import '../features/search/search_screen.dart';
import '../features/pre_orders/pre_order_checkout_screen.dart';
import '../features/pre_orders/pre_order_detail_screen.dart';
import '../features/track_order/track_order_screen.dart';
import '../features/compare/compare_screen.dart';
import '../features/email_preferences/email_preferences_screen.dart';

/// Routes that require a signed-in user. Anything not in this list is
/// accessible to guests (browsing products, viewing product details).
const _protectedRoutes = [
  '/cart',
  '/checkout',
  '/orders',
  '/wishlist',
  '/loyalty',
  '/profile',
  '/gift-cards',
  '/subscriptions',
  '/skin-quiz',
  '/referrals',
  '/pre-orders',
  '/returns',
  '/addresses',
  '/email-preferences',
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
      GoRoute(path: '/gift-cards', builder: (context, state) => const GiftCardsScreen()),
      GoRoute(path: '/subscriptions', builder: (context, state) => const SubscriptionsScreen()),
      GoRoute(
        path: '/subscriptions/:id',
        builder: (context, state) => SubscriptionDetailScreen(
          subscriptionId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/skin-quiz', builder: (context, state) => const SkinQuizScreen()),
      GoRoute(path: '/referrals', builder: (context, state) => const ReferralsScreen()),
      GoRoute(path: '/blog', builder: (context, state) => const BlogListScreen()),
      GoRoute(
        path: '/blog/:slug',
        builder: (context, state) => BlogArticleScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/pre-orders', builder: (context, state) => const PreOrdersScreen()),
      GoRoute(path: '/returns', builder: (context, state) => const ReturnsScreen()),
      GoRoute(path: '/addresses',
  builder: (context, state) => const AddressesScreen()),
      GoRoute(path: '/flash-sales', builder: (context, state) => const FlashSalesScreen()),
      GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
      GoRoute(path: '/track-order', builder: (context, state) => TrackOrderScreen(initialTrackingId: state.uri.queryParameters['id'])),
      GoRoute(path: '/compare', builder: (context, state) => const CompareScreen()),
      GoRoute(path: '/email-preferences', builder: (context, state) => const EmailPreferencesScreen()),
      GoRoute(path: '/pre-orders/:trackingId', builder: (context, state) => PreOrderDetailScreen(trackingId: state.pathParameters['trackingId']!)),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
    ],
  );
});

/// Depends on routerProvider (for notification-tap deep links) and
/// authServiceProvider (to know when to register/unregister the device's
/// FCM token) — defined here rather than in providers.dart to avoid a
/// circular import, since router.dart already imports providers.dart.
final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(
    ref.watch(pushRepositoryProvider),
    ref.watch(authServiceProvider),
    ref.watch(routerProvider),
  );
});
