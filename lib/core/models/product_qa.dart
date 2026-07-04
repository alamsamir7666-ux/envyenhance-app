/// Matches the response shape from `GET /products/:productId/qa`.
class ProductQuestion {
  ProductQuestion({
    required this.id,
    required this.userId,
    required this.userName,
    required this.question,
    this.answer,
    this.answeredAt,
    required this.createdAt,
  });

  factory ProductQuestion.fromJson(Map<String, dynamic> json) {
    return ProductQuestion(
      id: json['id'] as int,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String?,
      answeredAt: json['answeredAt'] != null
          ? DateTime.tryParse(json['answeredAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int id;
  final String userId;
  final String userName;
  final String question;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;

  bool get isAnswered => answer != null;
}
