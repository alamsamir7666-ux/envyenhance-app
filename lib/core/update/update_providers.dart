import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_service.dart';

/// Singleton UpdateService for the app's lifetime. Disposed when the
/// provider scope tears down (effectively never, outside tests).
final updateServiceProvider = Provider<UpdateService>((ref) {
  final service = UpdateService();
  ref.onDispose(service.dispose);
  return service;
});

/// UI-facing stream of update status. Screens watch this instead of
/// calling UpdateService methods directly so state survives navigation
/// between tabs (e.g. Profile -> Home -> Profile mid-download).
final updateStatusProvider = StreamProvider<UpdateStatus>((ref) {
  final service = ref.watch(updateServiceProvider);
  return service.statusStream;
});
