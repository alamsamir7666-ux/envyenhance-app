import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/return_request.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/async_states.dart';

final myReturnsProvider = FutureProvider<List<ReturnRequest>>((ref) async {
  ref.watch(authIdentityProvider);
  final repo = ref.watch(returnsRepositoryProvider);
  return repo.myReturns();
});

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(myReturnsProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('My Returns')),
      body: returnsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(myReturnsProvider),
        ),
        data: (returns) {
          if (returns.isEmpty) {
            return const EmptyView(
              icon: Icons.assignment_return_outlined,
              title: 'No return requests',
              subtitle: 'You can request a return from a delivered order within 7 days.',
            );
          }
          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () async => ref.invalidate(myReturnsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: returns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ReturnTile(returnRequest: returns[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ReturnTile extends StatelessWidget {
  const _ReturnTile({required this.returnRequest});
  final ReturnRequest returnRequest;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/orders/${returnRequest.orderId}'),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final statusColor = switch (returnRequest.status) {
      'approved' || 'completed' => brand.sage,
      'rejected' => theme.colorScheme.error,
      _ => brand.gold,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${returnRequest.orderId}',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              AppBadge.soft(
                text: returnRequest.status.toUpperCase(),
                color: statusColor,
                textColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(returnRequest.reason, style: theme.textTheme.bodyMedium),
          if (returnRequest.adminNote != null) ...[
            const SizedBox(height: 6),
            Text('Note: ${returnRequest.adminNote}', style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Shows a dialog to request a return for [orderId]. Called from the
/// order detail screen for delivered orders.
Future<void> showRequestReturnDialog(
  BuildContext context,
  WidgetRef ref, {
  required int orderId,
}) async {
  final reasonController = TextEditingController();
  String? error;
  bool isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Request a return'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please describe why you\'d like to return this order (min 10 characters).'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Reason for return'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.length < 10) {
                        setState(() => error = 'Please provide at least 10 characters');
                        return;
                      }
                      setState(() => isSubmitting = true);
                      try {
                        final repo = ref.read(returnsRepositoryProvider);
                        await repo.request(orderId: orderId, reason: reason);
                        ref.invalidate(myReturnsProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Return request submitted')),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          error = e.toString();
                          isSubmitting = false;
                        });
                      }
                    },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    ),
  );
}
