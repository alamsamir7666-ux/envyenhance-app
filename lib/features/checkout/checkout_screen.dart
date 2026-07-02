import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/cart.dart';
import '../../core/models/order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../cart/cart_providers.dart';

enum PaymentMethod { cod, bkash, nagad }

extension on PaymentMethod {
  String get apiValue => switch (this) {
        PaymentMethod.cod => 'cod',
        PaymentMethod.bkash => 'bkash',
        PaymentMethod.nagad => 'nagad',
      };

  String get label => switch (this) {
        PaymentMethod.cod => 'Cash on Delivery',
        PaymentMethod.bkash => 'bKash',
        PaymentMethod.nagad => 'Nagad',
      };

  bool get requiresSenderNumber => this != PaymentMethod.cod;
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _senderNumberController = TextEditingController();
  final _transactionIdController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _senderNumberController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(ordersRepositoryProvider);
      final order = await repo.placeOrder(
        paymentMethod: _paymentMethod.apiValue,
        senderNumber: _paymentMethod.requiresSenderNumber
            ? _senderNumberController.text.trim()
            : null,
        transactionId: _transactionIdController.text.trim().isEmpty
            ? null
            : _transactionIdController.text.trim(),
        shippingAddress: ShippingAddress(
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
        ),
      );

      // Order placed successfully — the backend clears the server-side
      // cart as part of order creation, so refresh local cart state to
      // match rather than assuming it's empty.
      await ref.read(cartProvider.notifier).refresh();

      if (mounted) {
        context.go('/orders/${order.id}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cartAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString()),
        data: (cart) {
          if (cart.isEmpty) {
            return const EmptyView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add products before checking out.',
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Shipping Address', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _streetController,
                  decoration: const InputDecoration(labelText: 'Street address'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                Text('Payment Method', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final method in PaymentMethod.values)
                  RadioListTile<PaymentMethod>(
                    value: method,
                    groupValue: _paymentMethod,
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                    title: Text(method.label),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                if (_paymentMethod.requiresSenderNumber) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _senderNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: '${_paymentMethod.label} sending number',
                    ),
                    validator: (v) {
                      if (_paymentMethod.requiresSenderNumber &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Required for ${_paymentMethod.label}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _transactionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID (optional)',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _OrderSummaryCard(cart: cart),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _placeOrder,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Place Order'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(formatTaka(cart.subtotal)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Delivery fee'),
              Text('Calculated by server'),
            ],
          ),
          const Divider(height: 20),
          Text(
            'Free delivery on orders over ৳2,000',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
