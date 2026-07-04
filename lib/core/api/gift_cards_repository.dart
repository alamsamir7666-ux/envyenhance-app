import '../models/gift_card.dart';
import 'api_client.dart';

class GiftCardsRepository {
  GiftCardsRepository(this._client);
  final ApiClient _client;

  /// Public balance check — used when a customer enters a gift card
  /// code at checkout/redemption, before we know if it's theirs.
  Future<GiftCardBalance> checkBalance(String code) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/gift-cards/check/${code.toUpperCase().trim()}',
    );
    return GiftCardBalance.fromJson(res.data!);
  }

  /// Gift cards the signed-in user has purchased (as gifts for others,
  /// or for themselves).
  Future<List<GiftCard>> myGiftCards() async {
    final res = await _client.get<List<dynamic>>('/gift-cards/my');
    return (res.data ?? [])
        .map((e) => GiftCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Purchases a new gift card. [amount] must be between ৳100 and
  /// ৳50,000 per the backend's validation.
  Future<GiftCard> purchase({
    required double amount,
    String? recipientEmail,
    String? recipientName,
    String? message,
    int? expiryDays,
  }) async {
    final res = await _client.post<Map<String, dynamic>>('/gift-cards', data: {
      'amount': amount,
      if (recipientEmail != null) 'recipientEmail': recipientEmail,
      if (recipientName != null) 'recipientName': recipientName,
      if (message != null) 'message': message,
      if (expiryDays != null) 'expiryDays': expiryDays,
    });
    return GiftCard.fromJson(res.data!);
  }

  /// Redeems [amount] from a gift card [code]. Returns the amount
  /// actually applied and the card's remaining balance. Note: this is a
  /// standalone balance debit, not wired into order placement on the
  /// backend — it's meant to be called by the app right before/after
  /// creating an order to manually apply store credit.
  Future<({double amountApplied, double remainingBalance})> redeem({
    required String code,
    required double amount,
  }) async {
    final res = await _client.post<Map<String, dynamic>>('/gift-cards/redeem', data: {
      'code': code,
      'amount': amount,
    });
    return (
      amountApplied: (res.data!['amountApplied'] as num).toDouble(),
      remainingBalance: (res.data!['remainingBalance'] as num).toDouble(),
    );
  }
}
