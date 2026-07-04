/// Matches the response shape from `POST /api/coupons/validate`.
class Coupon {
  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.expiryDate,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as int,
      code: json['code'] as String,
      discountType: json['discountType'] as String, // 'percentage' | 'fixed'
      discountValue: (json['discountValue'] as num).toDouble(),
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
    );
  }

  final int id;
  final String code;
  final String discountType;
  final double discountValue;
  final double? minOrderAmount;
  final DateTime? expiryDate;

  bool get isPercentage => discountType == 'percentage';

  /// Client-side preview only — the authoritative discount is always
  /// recalculated server-side when the order is actually placed.
  double previewDiscount(double orderAmount) {
    if (isPercentage) return orderAmount * (discountValue / 100);
    return discountValue;
  }
}
