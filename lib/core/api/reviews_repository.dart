import 'package:dio/dio.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewEligibility {
  ReviewEligibility({required this.canReview, this.reason});
  final bool canReview;
  final String? reason; // "already_reviewed" | "not_purchased" | null

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) =>
      ReviewEligibility(
        canReview: json['canReview'] as bool? ?? false,
        reason: json['reason'] as String?,
      );
}

class ReviewsRepository {
  ReviewsRepository(this._client);
  final ApiClient _client;

  Future<List<Review>> forProduct(int productId) async {
    final res = await _client.get<List<dynamic>>('/reviews/$productId');
    return (res.data ?? [])
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Whether the current user has purchased this product and hasn't
  /// already reviewed it — the backend requires both.
  Future<ReviewEligibility> checkEligibility(int productId) async {
    final res = await _client
        .get<Map<String, dynamic>>('/reviews/$productId/eligibility');
    return ReviewEligibility.fromJson(res.data!);
  }

  /// Submits a review. [photoPaths] are local file paths (max 4), optional.
  Future<Review> submit({
    required int productId,
    required int rating,
    required String comment,
    List<String> photoPaths = const [],
  }) async {
    final formData = FormData.fromMap({
      'rating': rating.toString(),
      'comment': comment,
      'photos': [
        for (final path in photoPaths.take(4))
          await MultipartFile.fromFile(path, filename: path.split('/').last),
      ],
    });

    final res = await _client.dio.post<Map<String, dynamic>>(
      '/reviews/$productId',
      data: formData,
    );
    return Review.fromJson(res.data!);
  }

  Future<void> delete(int productId, int reviewId) async {
    await _client.delete<dynamic>('/reviews/$productId/$reviewId');
  }
}
