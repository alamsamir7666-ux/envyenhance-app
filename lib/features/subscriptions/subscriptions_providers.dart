import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/subscription.dart';
import '../../core/providers.dart';

final mySubscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  ref.watch(authIdentityProvider);
  final repo = ref.watch(subscriptionsRepositoryProvider);
  return repo.myList();
});

final subscriptionDetailProvider =
    FutureProvider.family<Subscription, int>((ref, id) async {
  final repo = ref.watch(subscriptionsRepositoryProvider);
  return repo.getById(id);
});
