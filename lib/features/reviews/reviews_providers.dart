import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/review.dart';
import '../../core/providers.dart';
import '../../core/api/reviews_repository.dart';

final productReviewsProvider =
    FutureProvider.family<List<Review>, int>((ref, productId) async {
  final repo = ref.watch(reviewsRepositoryProvider);
  return repo.forProduct(productId);
});

/// Whether the current user is eligible to write a review (has purchased
/// and hasn't already reviewed). Guests will get a 401 from the backend;
/// treat that as "not eligible" rather than surfacing an error, since
/// the review button just won't show for signed-out users.
final reviewEligibilityProvider =
    FutureProvider.family<ReviewEligibility, int>((ref, productId) async {
  final repo = ref.watch(reviewsRepositoryProvider);
  try {
    return await repo.checkEligibility(productId);
  } catch (_) {
    return ReviewEligibility(canReview: false, reason: 'not_signed_in');
  }
});
