/// Matches the `fmt()` response shape from `returns.ts`.
class ReturnRequest {
  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.status,
    this.adminNote,
    this.refundAmount,
    required this.createdAt,
  });

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      reason: json['reason'] as String,
      status: json['status'] as String,
      adminNote: json['adminNote'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int id;
  final int orderId;
  final String reason;
  final String status; // requested | approved | rejected | completed
  final String? adminNote;
  final double? refundAmount;
  final DateTime createdAt;
}
