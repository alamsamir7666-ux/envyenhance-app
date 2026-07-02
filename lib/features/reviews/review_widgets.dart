import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_service.dart';
import '../../core/models/review.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import 'reviews_providers.dart';

/// Reviews list + "write a review" entry point, embedded within the
/// product detail screen.
class ProductReviewsSection extends ConsumerWidget {
  const ProductReviewsSection({required this.productId, super.key});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    final auth = ref.watch(authServiceProvider);
    final eligibilityAsync =
        auth.isSignedIn ? ref.watch(reviewEligibilityProvider(productId)) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
            if (eligibilityAsync != null)
              eligibilityAsync.maybeWhen(
                data: (e) => e.canReview
                    ? TextButton(
                        onPressed: () => _showWriteReviewSheet(context, ref, productId),
                        child: const Text('Write a review'),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: LoadingView(),
          ),
          error: (err, _) => Text(
            'Couldn\'t load reviews.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No reviews yet. Be the first to share your experience!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            return Column(
              children: reviews.map((r) => _ReviewTile(review: r)).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showWriteReviewSheet(BuildContext context, WidgetRef ref, int productId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WriteReviewSheet(productId: productId),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.userName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const Spacer(),
              Text(formatDate(review.createdAt), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          StarRatingDisplay(rating: review.rating),
          const SizedBox(height: 4),
          Text(review.comment, style: Theme.of(context).textTheme.bodyLarge),
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.photos[i],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 20),
        ],
      ),
    );
  }
}

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({required this.rating, this.size = 16, super.key});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

/// Bottom sheet form for submitting a new review with a star rating and
/// comment. Photo upload is supported by the repository layer but kept
/// out of v1 UI to start simple — text reviews cover the core use case.
class WriteReviewSheet extends ConsumerStatefulWidget {
  const WriteReviewSheet({required this.productId, super.key});
  final int productId;

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.length < 5) {
      setState(() => _error = 'Please write at least 5 characters.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(reviewsRepositoryProvider).submit(
            productId: widget.productId,
            rating: _rating,
            comment: comment,
          );
      ref.invalidate(productReviewsProvider(widget.productId));
      ref.invalidate(reviewEligibilityProvider(widget.productId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Write a review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: AppColors.accent,
                  size: 32,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              ),
            ),
          ),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Share your experience with this product…',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
}
