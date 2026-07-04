import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/blog_post.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/widgets/async_states.dart';

final blogPostsProvider = FutureProvider<List<BlogPost>>((ref) async {
  final repo = ref.watch(blogRepositoryProvider);
  return repo.list();
});

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(blogPostsProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Skincare Journal')),
      body: postsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(blogPostsProvider),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyView(
              icon: Icons.article_outlined,
              title: 'No articles yet',
              subtitle: 'Check back soon for skincare tips and guides.',
            );
          }
          final featured = posts.where((p) => p.featured).firstOrNull ?? posts.first;
          final rest = posts.where((p) => p.slug != featured.slug).toList();

          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () async => ref.invalidate(blogPostsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _FeaturedPostCard(post: featured),
                const SizedBox(height: 20),
                for (final post in rest) _PostListTile(post: post),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _FeaturedPostCard extends StatelessWidget {
  const _FeaturedPostCard({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/blog/${post.slug}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: post.image.isNotEmpty
                  ? CachedNetworkImage(imageUrl: post.image, fit: BoxFit.cover)
                  : Container(color: brand.roseSurface),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.category.toUpperCase(),
                    style: TextStyle(color: brand.gold, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(post.title, style: theme.textTheme.displaySmall?.copyWith(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    post.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(post.readTime, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostListTile extends StatelessWidget {
  const _PostListTile({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/blog/${post.slug}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: post.image.isNotEmpty
                    ? CachedNetworkImage(imageUrl: post.image, fit: BoxFit.cover)
                    : Container(color: brand.roseSurface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.category.toUpperCase(),
                    style: TextStyle(color: brand.gold, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(post.readTime, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
