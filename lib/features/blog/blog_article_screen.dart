import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blog_post.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/widgets/async_states.dart';

final blogArticleProvider = FutureProvider.family<BlogPost, String>((ref, slug) async {
  final repo = ref.watch(blogRepositoryProvider);
  return repo.bySlug(slug);
});

class BlogArticleScreen extends ConsumerWidget {
  const BlogArticleScreen({required this.slug, super.key});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(blogArticleProvider(slug));

    return Scaffold(
      body: postAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(blogArticleProvider(slug)),
        ),
        data: (post) {
          final theme = Theme.of(context);
          final brand = context.brand;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: theme.scaffoldBackgroundColor,
                foregroundColor: theme.colorScheme.onSurface,
                flexibleSpace: FlexibleSpaceBar(
                  background: post.image.isNotEmpty
                      ? CachedNetworkImage(imageUrl: post.image, fit: BoxFit.cover)
                      : Container(color: brand.roseSurface),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.category.toUpperCase(),
                        style: TextStyle(color: brand.gold, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(post.title, style: theme.textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text(post.readTime, style: theme.textTheme.bodyMedium),
                      const Divider(height: 32),
                      for (final block in post.content) _ContentBlockWidget(block: block),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContentBlockWidget extends StatelessWidget {
  const _ContentBlockWidget({required this.block});
  final BlogContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return switch (block) {
      BlogHeading(:final text, :final level) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            text,
            style: level == 2
                ? theme.textTheme.headlineMedium
                : theme.textTheme.titleLarge,
          ),
        ),
      BlogParagraph(:final text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
        ),
      BlogList(:final items) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: theme.textTheme.bodyLarge?.copyWith(color: brand.gold)),
                      Expanded(child: Text(item, style: theme.textTheme.bodyLarge)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      BlogTip(:final text) => Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: brand.gold.withValues(alpha: 0.08),
            border: Border.all(color: brand.gold.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: brand.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
    };
  }
}
