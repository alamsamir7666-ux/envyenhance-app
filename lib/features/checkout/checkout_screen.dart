import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/coupons_repository.dart';
import '../../core/models/cart.dart';
import '../../core/models/coupon.dart';
import '../../core/models/order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
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
  final _couponController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isSubmitting = false;
  String? _error;

  Coupon? _appliedCoupon;
  bool _isValidatingCoupon = false;
  String? _couponError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _senderNumberController.dispose();
    _transactionIdController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(double orderAmount) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });
    try {
      final repo = ref.read(couponsRepositoryProvider);
      final coupon = await repo.validate(code: code, orderAmount: orderAmount);
      setState(() => _appliedCoupon = coupon);
    } on CouponValidationException catch (e) {
      setState(() => _couponError = e.message);
    } catch (e) {
      setState(() => _couponError = 'Could not validate coupon. Please try again.');
    } finally {
      if (mounted) setState(() => _isValidatingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponError = null;
      _couponController.clear();
    });
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
        couponCode: _appliedCoupon?.code,
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
                RadioGroup<PaymentMethod>(
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  child: Column(
                    children: [
                      for (final method in PaymentMethod.values)
                        RadioListTile<PaymentMethod>(
                          value: method,
                          title: Text(method.label),
                          activeColor: Theme.of(context).colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
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
                Text('Coupon Code', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (_appliedCoupon != null)
                  _AppliedCouponChip(coupon: _appliedCoupon!, onRemove: _removeCoupon)
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Enter coupon code',
                            errorText: _couponError,
                          ),
                          onSubmitted: (_) => _applyCoupon(cart.subtotal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isValidatingCoupon ? null : () => _applyCoupon(cart.subtotal),
                          child: _isValidatingCoupon
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                _OrderSummaryCard(cart: cart, appliedCoupon: _appliedCoupon),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

class _AppliedCouponChip extends StatelessWidget {
  const _AppliedCouponChip({required this.coupon, required this.onRemove});
  final Coupon coupon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: brand.sage.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.sage.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined, color: brand.sage, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${coupon.code} applied — ${coupon.isPercentage ? '${coupon.discountValue.toStringAsFixed(0)}% off' : '${formatTaka(coupon.discountValue)} off'}',
              style: TextStyle(color: brand.sage, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            tooltip: 'Remove coupon',
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cart, this.appliedCoupon});
  final Cart cart;
  final Coupon? appliedCoupon;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final previewDiscount = appliedCoupon?.previewDiscount(cart.subtotal) ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.roseSurface.withValues(alpha: 0.6),
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
          if (previewDiscount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupon discount', style: TextStyle(color: brand.sage)),
                Text('-${formatTaka(previewDiscount)}', style: TextStyle(color: brand.sage)),
              ],
            ),
          ],
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
            'Free delivery on orders over ৳2,000. Final total (including any discounts) is confirmed on the order confirmation screen.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
