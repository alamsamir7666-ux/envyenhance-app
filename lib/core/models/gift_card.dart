/// Matches the `formatCard()` response shape from `giftCards.ts`.
class GiftCard {
  GiftCard({
    required this.id,
    required this.code,
    required this.initialBalance,
    required this.balance,
    required this.isActive,
    this.recipientEmail,
    this.recipientName,
    this.message,
    this.expiryDate,
    required this.createdAt,
  });

  factory GiftCard.fromJson(Map<String, dynamic> json) {
    return GiftCard(
      id: json['id'] as int,
      code: json['code'] as String,
      initialBalance: (json['initialBalance'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      recipientEmail: json['recipientEmail'] as String?,
      recipientName: json['recipientName'] as String?,
      message: json['message'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int id;
  final String code;
  final double initialBalance;
  final double balance;
  final bool isActive;
  final String? recipientEmail;
  final String? recipientName;
  final String? message;
  final DateTime? expiryDate;
  final DateTime createdAt;
}

/// Result of `GET /gift-cards/check/:code` — the public balance-check
/// used at redemption time, intentionally slimmer than the full
/// [GiftCard] (no id, no purchaser info).
class GiftCardBalance {
  GiftCardBalance({
    required this.code,
    required this.balance,
    this.recipientName,
    this.expiryDate,
  });

  factory GiftCardBalance.fromJson(Map<String, dynamic> json) {
    return GiftCardBalance(
      code: json['code'] as String,
      balance: (json['balance'] as num).toDouble(),
      recipientName: json['recipientName'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
    );
  }

  final String code;
  final double balance;
  final String? recipientName;
  final DateTime? expiryDate;
}
