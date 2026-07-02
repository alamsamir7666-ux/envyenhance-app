/// Matches `formatReview()` in `src/routes/reviews.ts`.
class Review {
  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.photos,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      productId: json['productId'] as int,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      photos: (json['photos'] as List?)?.cast<String>() ?? const [],
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final int id;
  final int productId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final List<String> photos;
  final String createdAt;
}
