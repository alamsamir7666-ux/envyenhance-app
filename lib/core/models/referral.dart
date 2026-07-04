/// Matches the response shape from `GET /referrals/my-code`.
class ReferralStatus {
  ReferralStatus({
    required this.code,
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.earnedPoints,
    required this.shareUrl,
  });

  factory ReferralStatus.fromJson(Map<String, dynamic> json) {
    return ReferralStatus(
      code: json['code'] as String,
      totalReferrals: json['totalReferrals'] as int,
      successfulReferrals: json['successfulReferrals'] as int,
      earnedPoints: json['earnedPoints'] as int,
      shareUrl: json['shareUrl'] as String,
    );
  }

  final String code;
  final int totalReferrals;
  final int successfulReferrals;
  final int earnedPoints;
  final String shareUrl;
}
