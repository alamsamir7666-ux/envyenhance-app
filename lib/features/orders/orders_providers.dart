import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order.dart';
import '../../core/providers.dart';

final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.myOrders();
});

final orderDetailProvider = FutureProvider.family<Order, int>((ref, orderId) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.getById(orderId);
});
