import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/cart_providers.dart';
import '../theme/app_theme.dart';

/// Persistent bottom-nav shell wrapping the five primary tabs. Matches
/// industry-standard e-commerce IA: Home, Browse, Cart, Wishlist, Profile.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    _TabDef(path: '/', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _TabDef(path: '/products', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Browse'),
    _TabDef(path: '/cart', icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Cart'),
    _TabDef(path: '/wishlist', icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Wishlist'),
    _TabDef(path: '/profile', icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  int _indexForLocation(String location) {
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (i == 0 ? location == '/' : location.startsWith(_tabs[i].path)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) context.go(_tabs[index].path);
        },
        items: [
          for (int i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(
              icon: _tabs[i].path == '/cart' && cartCount > 0
                  ? Badge(
                      label: Text('$cartCount'),
                      backgroundColor: AppColors.primary,
                      child: Icon(_tabs[i].icon),
                    )
                  : Icon(_tabs[i].icon),
              activeIcon: Icon(_tabs[i].activeIcon),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}

class _TabDef {
  const _TabDef({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
