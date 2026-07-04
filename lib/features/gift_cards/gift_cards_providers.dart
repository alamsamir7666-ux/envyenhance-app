import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/gift_card.dart';
import '../../core/providers.dart';

final myGiftCardsProvider = FutureProvider<List<GiftCard>>((ref) async {
  ref.watch(authIdentityProvider);
  final repo = ref.watch(giftCardsRepositoryProvider);
  return repo.myGiftCards();
});
