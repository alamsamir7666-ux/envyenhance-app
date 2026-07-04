import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';

/// Replaces the Add-to-Cart button when a product is out of stock,
/// letting the user register for a restock notification.
class StockAlertButton extends ConsumerStatefulWidget {
  const StockAlertButton({required this.productId, super.key});
  final int productId;

  @override
  ConsumerState<StockAlertButton> createState() => _StockAlertButtonState();
}

class _StockAlertButtonState extends ConsumerState<StockAlertButton> {
  bool _subscribed = false;

  Future<void> _showSubscribeDialog() async {
    final controller = TextEditingController();
    String? error;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Notify me when in stock'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We\'ll email you as soon as this product is back.'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Your email address'),
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
                        final email = controller.text.trim();
                        if (!email.contains('@')) {
                          setState(() => error = 'Enter a valid email address');
                          return;
                        }
                        setState(() => isSubmitting = true);
                        try {
                          final repo = ref.read(stockAlertsRepositoryProvider);
                          await repo.subscribe(productId: widget.productId, email: email);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          this.setState(() => _subscribed = true);
                        } catch (e) {
                          setState(() {
                            error = e.toString();
                            isSubmitting = false;
                          });
                        }
                      },
                child: const Text('Notify me'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    if (_subscribed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: Icon(Icons.check_circle_outline, color: brand.sage),
          label: const Text('We\'ll notify you'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showSubscribeDialog,
        icon: const Icon(Icons.notifications_outlined),
        label: const Text('Notify me when in stock'),
      ),
    );
  }
}
