import '../models/referral.dart';
import 'api_client.dart';

class ReferralsRepository {
  ReferralsRepository(this._client);
  final ApiClient _client;

  Future<ReferralStatus> myCode() async {
    final res = await _client.get<Map<String, dynamic>>('/referrals/my-code');
    return ReferralStatus.fromJson(res.data!);
  }

  /// Applies a referral code (typically once, right after first sign-in).
  /// Returns the one-time coupon code the new user earns.
  Future<String> apply(String code) async {
    final res = await _client.post<Map<String, dynamic>>('/referrals/apply', data: {
      'code': code,
    });
    return res.data!['couponCode'] as String;
  }
}
