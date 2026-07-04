import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/misc.dart';
import '../../core/providers.dart';

/// The signed-in user's saved addresses. Watches [authIdentityProvider] so
/// it correctly refetches (rather than serving stale data) if the signed-in
/// user changes.
final myAddressesProvider = FutureProvider<List<Address>>((ref) async {
  ref.watch(authIdentityProvider);
  final repo = ref.watch(usersRepositoryProvider);
  return repo.myAddresses();
});

/// Convenience accessor for the default (or first) saved address, used to
/// pre-select an address at checkout without making the checkout screen
/// re-implement the "which one is default" logic.
final defaultAddressProvider = Provider<Address?>((ref) {
  final addresses = ref.watch(myAddressesProvider).value;
  if (addresses == null || addresses.isEmpty) return null;
  return addresses.firstWhere(
    (a) => a.isDefault,
    orElse: () => addresses.first,
  );
});
