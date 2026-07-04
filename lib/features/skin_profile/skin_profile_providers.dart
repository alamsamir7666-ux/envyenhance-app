import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/skin_profile.dart';
import '../../core/providers.dart';

final skinProfileProvider = FutureProvider<SkinProfile?>((ref) async {
  ref.watch(authIdentityProvider);
  final repo = ref.watch(skinProfileRepositoryProvider);
  return repo.myProfile();
});
