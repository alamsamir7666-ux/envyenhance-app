import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';

final loyaltyStatusProvider = FutureProvider((ref) async {
  final repo = ref.watch(loyaltyRepositoryProvider);
  return repo.myStatus();
});

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyAsync = ref.watch(loyaltyStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Points')),
      body: loyaltyAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(loyaltyStatusProvider),
        ),
        data: (status) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(loyaltyStatusProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF8F4460)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${status.points} points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Worth ${formatTaka(status.takaValue)} in discounts',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Earn 1 point for every ৳100 you spend. 1 point = ৳1 off your next order.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('History', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (status.transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No transactions yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  for (final tx in status.transactions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            tx.isEarned ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                        child: Icon(
                          tx.isEarned ? Icons.add : Icons.remove,
                          color: tx.isEarned ? AppColors.success : AppColors.error,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        tx.orderId != null ? 'Order #${tx.orderId}' : tx.reason,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(formatDate(tx.createdAt)),
                      trailing: Text(
                        '${tx.isEarned ? '+' : ''}${tx.points}',
                        style: TextStyle(
                          color: tx.isEarned ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
