import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  final service = UpdateService();
  ref.onDispose(service.dispose);
  return service;
});

/// Seeds with the current status so UI never misses events emitted
/// before the StreamProvider subscribed (e.g. during app launch).
final updateStatusProvider = StreamProvider<UpdateStatus>((ref) {
  final service = ref.watch(updateServiceProvider);
  return Stream.value(service.status).asyncExpand(
    (_) => service.statusStream,
  );
});
