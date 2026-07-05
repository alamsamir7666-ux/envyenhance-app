import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/product.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';

// Holds the two product IDs being compared
final compareIdsProvider = StateProvider<List<int>>((ref) => []);

final compareProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final ids = ref.watch(compareIdsProvider);
  if (ids.isEmpty) return [];
  final repo = ref.watch(productsRepositoryProvider);
  final results = await Future.wait(ids.map((id) => repo.getById(id)));
  return results;
});

const _compareRows = [
  ('category', 'Category'),
  ('price', 'Price'),
  ('rating', 'Rating'),
  ('stock', 'Availability'),
  ('texture', 'Texture'),
  ('bestFor', 'Best For'),
  ('keyBenefits', 'Key Benefits'),
];

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(compareIdsProvider);
    final productsAsync = ref.watch(compareProductsProvider);
    final brand = context.brand;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        actions: [
          if (ids.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(compareIdsProvider.notifier).state = [],
              child: const Text('Clear'),
            ),
        ],
      ),
      body: ids.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.balance_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No products to compare',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Add products from the product detail page.',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.push('/products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand.gold,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            )
          : productsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (products) => _CompareTable(products: products),
            ),
    );
  }
}

class _CompareTable extends ConsumerWidget {
  const _CompareTable({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final ids = ref.watch(compareIdsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header row with product images + names
          Container(
            color: theme.cardTheme.color,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const SizedBox(width: 100), // label column
                ...products.map((p) => Expanded(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: p.primaryImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: p.primaryImage,
                                        height: 90,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 90,
                                        color: brand.blush,
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(compareIdsProvider.notifier).state =
                                        ids.where((id) => id != p.id).toList();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => context.push('/products/${p.id}'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('View'),
                          ),
                        ],
                      ),
                    )),
                // Add slot if < 2 products
                if (products.length < 2)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/products'),
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: theme.dividerColor, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: brand.gold),
                            Text('Add product',
                                style: TextStyle(fontSize: 11, color: brand.gold)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comparison rows
          for (final (key, label) in _compareRows)
            _CompareRow(label: label, rowKey: key, products: products),

          // Add to cart row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const SizedBox(width: 100),
                ...products.map((p) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () => context.push('/products/${p.id}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brand.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('View', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.rowKey,
    required this.products,
  });
  final String label;
  final String rowKey;
  final List<Product> products;

  String _value(Product p) {
    switch (rowKey) {
      case 'category':
        return p.category;
      case 'price':
        return p.isOnSale
            ? '${formatTaka(p.effectivePrice)} (was ${formatTaka(p.price)})'
            : formatTaka(p.price);
      case 'rating':
        return '${p.averageRating.toStringAsFixed(1)} ⭐ (${p.reviewCount})';
      case 'stock':
        return p.inStock ? 'In stock (${p.stock})' : 'Out of stock';
      case 'texture':
        return p.texture ?? '—';
      case 'bestFor':
        return p.bestFor.isEmpty ? '—' : p.bestFor.join(', ');
      case 'keyBenefits':
        return p.keyBenefits.isEmpty ? '—' : p.keyBenefits.join('\n• ');
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 100,
              padding: const EdgeInsets.all(10),
              color: theme.colorScheme.surface,
              child: Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ...products.map((p) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(color: theme.dividerColor)),
                    ),
                    child: Text(
                      _value(p),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )),
            if (products.length < 2)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border:
                        Border(left: BorderSide(color: theme.dividerColor)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
