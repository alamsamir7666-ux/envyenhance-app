import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/gift_card.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import 'gift_cards_providers.dart';

class GiftCardsScreen extends ConsumerWidget {
  const GiftCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(myGiftCardsProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Gift Cards')),
      body: cardsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(myGiftCardsProvider),
        ),
        data: (cards) {
          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () async => ref.invalidate(myGiftCardsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [const Color(0xFF23201C), const Color(0xFF3A2B2E)]
                          : [const Color(0xFF2E2724), const Color(0xFF4A3630)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Give the gift of glowing skin',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(color: Colors.white, fontSize: 22),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Gift cards from ৳100 to ৳50,000',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brand.gold,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showPurchaseSheet(context, ref),
                        child: const Text('Buy a gift card'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Your gift cards', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'You haven\'t purchased any gift cards yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  for (final card in cards) _GiftCardTile(card: card),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _PurchaseGiftCardSheet(),
    );
  }
}

class _GiftCardTile extends StatelessWidget {
  const _GiftCardTile({required this.card});
  final GiftCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final isDepleted = card.balance <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, color: isDepleted ? brand.textSecondary : brand.gold, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.code,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: 'Copy code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: card.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
                        );
                      },
                    ),
                  ],
                ),
                if (card.recipientName != null)
                  Text('For ${card.recipientName}', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  isDepleted
                      ? 'Fully redeemed'
                      : '${formatTaka(card.balance)} remaining of ${formatTaka(card.initialBalance)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDepleted ? brand.textSecondary : brand.sage,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseGiftCardSheet extends ConsumerStatefulWidget {
  const _PurchaseGiftCardSheet();

  @override
  ConsumerState<_PurchaseGiftCardSheet> createState() => _PurchaseGiftCardSheetState();
}

class _PurchaseGiftCardSheetState extends ConsumerState<_PurchaseGiftCardSheet> {
  static const _presetAmounts = [500.0, 1000.0, 2500.0, 5000.0];

  double? _selectedAmount;
  final _customAmountController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientEmailController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _customAmountController.dispose();
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  double? get _effectiveAmount {
    if (_customAmountController.text.trim().isNotEmpty) {
      return double.tryParse(_customAmountController.text.trim());
    }
    return _selectedAmount;
  }

  Future<void> _submit() async {
    final amount = _effectiveAmount;
    if (amount == null || amount < 100 || amount > 50000) {
      setState(() => _error = 'Enter an amount between ৳100 and ৳50,000');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(giftCardsRepositoryProvider);
      await repo.purchase(
        amount: amount,
        recipientName:
            _recipientNameController.text.trim().isEmpty ? null : _recipientNameController.text.trim(),
        recipientEmail:
            _recipientEmailController.text.trim().isEmpty ? null : _recipientEmailController.text.trim(),
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      ref.invalidate(myGiftCardsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gift card purchased!')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buy a gift card', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final amount in _presetAmounts)
                  ChoiceChip(
                    label: Text(formatTaka(amount)),
                    selected: _selectedAmount == amount && _customAmountController.text.isEmpty,
                    onSelected: (_) => setState(() {
                      _selectedAmount = amount;
                      _customAmountController.clear();
                    }),
                    selectedColor: brand.gold.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Or enter custom amount (৳100–৳50,000)'),
              onChanged: (_) => setState(() => _selectedAmount = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientNameController,
              decoration: const InputDecoration(labelText: 'Recipient name (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recipientEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Recipient email (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Gift message (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Purchase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
