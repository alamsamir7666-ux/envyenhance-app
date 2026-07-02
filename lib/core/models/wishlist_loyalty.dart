import 'cart.dart';

/// Matches `/wishlist` response shape in `src/routes/wishlist.ts`.
class WishlistItem {
  WishlistItem({
    required this.id,
    required this.productId,
    required this.addedAt,
    required this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as int,
      productId: json['productId'] as int,
      addedAt: json['addedAt'] as String? ?? '',
      product: CartProduct.fromJson(
        (json['product'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  final int id;
  final int productId;
  final String addedAt;
  final CartProduct product;
}

/// Matches `/loyalty/me` response shape in `src/routes/loyalty.ts`.
/// 1 point = ৳1 discount; earned at 1 point per ৳100 spent.
class LoyaltyStatus {
  LoyaltyStatus({
    required this.points,
    required this.takaValue,
    required this.transactions,
  });

  factory LoyaltyStatus.fromJson(Map<String, dynamic> json) {
    return LoyaltyStatus(
      points: json['points'] as int? ?? 0,
      takaValue: (json['takaValue'] as num?)?.toDouble() ?? 0,
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int points;
  final double takaValue;
  final List<LoyaltyTransaction> transactions;

  static LoyaltyStatus empty() =>
      LoyaltyStatus(points: 0, takaValue: 0, transactions: []);
}

class LoyaltyTransaction {
  LoyaltyTransaction({
    required this.id,
    required this.points,
    required this.reason,
    this.orderId,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] as int,
      points: json['points'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      orderId: json['orderId'] as int?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final int id;
  final int points;
  final String reason;
  final int? orderId;
  final String createdAt;

  bool get isEarned => points > 0;
}
