import '../models/coupon.dart';
import 'api_client.dart';

/// Thrown when a coupon fails validation, carrying the server's exact
/// human-readable reason (invalid, expired, below minimum order amount)
/// so the checkout UI can show it directly rather than a generic error.
class CouponValidationException implements Exception {
  CouponValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CouponsRepository {
  CouponsRepository(this._client);
  final ApiClient _client;

  /// Validates a coupon code against the current order amount. This is a
  /// public endpoint (no auth required) — the same one used at checkout
  /// on the website. Throws [CouponValidationException] with the
  /// server's message on any 4xx response (invalid code, expired,
  /// below minimum spend).
  Future<Coupon> validate({required String code, required double orderAmount}) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        '/coupons/validate',
        data: {'code': code, 'orderAmount': orderAmount},
      );
      return Coupon.fromJson(res.data!);
    } on ApiException catch (e) {
      throw CouponValidationException(e.message);
    }
  }
}
