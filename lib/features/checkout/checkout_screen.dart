import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/coupons_repository.dart';
import '../../core/models/cart.dart';
import '../../core/models/coupon.dart';
import '../../core/models/gift_card.dart';
import '../../core/models/misc.dart';
import '../../core/models/order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../addresses/addresses_providers.dart';
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

  // Manual-entry controllers, used only when no saved address is selected.
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _senderNumberController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _couponController = TextEditingController();
  final _giftCardController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isSubmitting = false;
  String? _error;

  Coupon? _appliedCoupon;
  bool _isValidatingCoupon = false;
  String? _couponError;

  GiftCardBalance? _appliedGiftCard;
  bool _isValidatingGiftCard = false;
  String? _giftCardError;

  Address? _selectedAddress;
  bool _useNewAddress = false;
  bool _addressInitialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _senderNumberController.dispose();
    _transactionIdController.dispose();
    _couponController.dispose();
    _giftCardController.dispose();
    super.dispose();
  }

  void _initializeAddressIfNeeded(List<Address> addresses) {
    if (_addressInitialized) return;
    _addressInitialized = true;
    if (addresses.isNotEmpty) {
      _selectedAddress = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
    } else {
      _useNewAddress = true;
    }
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

  Future<void> _applyGiftCard() async {
    final code = _giftCardController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isValidatingGiftCard = true;
      _giftCardError = null;
    });
    try {
      final repo = ref.read(giftCardsRepositoryProvider);
      final balance = await repo.checkBalance(code);
      setState(() => _appliedGiftCard = balance);
    } on ApiException catch (e) {
      setState(() => _giftCardError = e.message);
    } catch (e) {
      setState(() => _giftCardError = 'Could not check gift card. Please try again.');
    } finally {
      if (mounted) setState(() => _isValidatingGiftCard = false);
    }
  }

  void _removeGiftCard() {
    setState(() {
      _appliedGiftCard = null;
      _giftCardError = null;
      _giftCardController.clear();
    });
  }

  ShippingAddress _buildShippingAddress() {
    if (!_useNewAddress && _selectedAddress != null) {
      final a = _selectedAddress!;
      return ShippingAddress(
        fullName: a.fullName,
        phone: a.phone,
        street: a.street,
        city: a.city,
        district: a.district,
        postalCode: a.postalCode,
      );
    }
    return ShippingAddress(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    String? warning;

    try {
      final ordersRepo = ref.read(ordersRepositoryProvider);
      final order = await ordersRepo.placeOrder(
        paymentMethod: _paymentMethod.apiValue,
        senderNumber: _paymentMethod.requiresSenderNumber
            ? _senderNumberController.text.trim()
            : null,
        transactionId: _transactionIdController.text.trim().isEmpty
            ? null
            : _transactionIdController.text.trim(),
        shippingAddress: _buildShippingAddress(),
        couponCode: _appliedCoupon?.code,
      );

      // Gift card redemption happens as a separate step after the order is
      // created, since the backend doesn't fold it into order totals — see
      // GiftCardsRepository.redeem() doc comment. If this fails (e.g. the
      // balance was drained by a race), the order itself still stands, so
      // we surface it as a warning rather than blocking navigation.
      if (_appliedGiftCard != null) {
        final amountToRedeem = _appliedGiftCard!.balance < order.totalAmount
            ? _appliedGiftCard!.balance
            : order.totalAmount;
        try {
          await ref.read(giftCardsRepositoryProvider).redeem(
                code: _appliedGiftCard!.code,
                amount: amountToRedeem,
              );
        } catch (e) {
          warning =
              'Order placed, but the gift card could not be redeemed: $e. Please contact support if you were charged.';
        }
      }

      // Order placed successfully — the backend clears the server-side
      // cart as part of order creation, so refresh local cart state to
      // match rather than assuming it's empty.
      await ref.read(cartProvider.notifier).refresh();
      ref.invalidate(myAddressesProvider);

      if (mounted) {
        if (warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(warning), duration: const Duration(seconds: 6)),
          );
        }
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
    final addressesAsync = ref.watch(myAddressesProvider);
    final theme = Theme.of(context);

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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                const _SectionHeading(title: 'Delivery Address'),
                const SizedBox(height: 14),
                addressesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => _ManualAddressForm(
                    fullNameController: _fullNameController,
                    phoneController: _phoneController,
                    streetController: _streetController,
                    cityController: _cityController,
                  ),
                  data: (addresses) {
                    _initializeAddressIfNeeded(addresses);
                    return _AddressPicker(
                      addresses: addresses,
                      selected: _selectedAddress,
                      useNewAddress: _useNewAddress,
                      onSelect: (a) => setState(() {
                        _selectedAddress = a;
                        _useNewAddress = false;
                      }),
                      onUseNewAddress: () => setState(() {
                        _useNewAddress = true;
                        _selectedAddress = null;
                      }),
                      manualForm: _ManualAddressForm(
                        fullNameController: _fullNameController,
                        phoneController: _phoneController,
                        streetController: _streetController,
                        cityController: _cityController,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const _SectionHeading(title: 'Payment Method'),
                const SizedBox(height: 14),
                _PaymentMethodPicker(
                  selected: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v),
                ),
                if (_paymentMethod.requiresSenderNumber) ...[
                  const SizedBox(height: 14),
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
                const SizedBox(height: 32),
                const _SectionHeading(title: 'Savings'),
                const SizedBox(height: 14),
                if (_appliedCoupon != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AppliedChip(
                      icon: Icons.local_offer_outlined,
                      label:
                          '${_appliedCoupon!.code} applied — ${_appliedCoupon!.isPercentage ? '${_appliedCoupon!.discountValue.toStringAsFixed(0)}% off' : '${formatTaka(_appliedCoupon!.discountValue)} off'}',
                      onRemove: _removeCoupon,
                    ),
                  )
                else
                  _InlineCodeField(
                    controller: _couponController,
                    hint: 'Enter coupon code',
                    buttonLabel: 'Apply',
                    isLoading: _isValidatingCoupon,
                    errorText: _couponError,
                    onSubmit: () => _applyCoupon(cart.subtotal),
                    textCapitalization: TextCapitalization.characters,
                  ),
                const SizedBox(height: 12),
                if (_appliedGiftCard != null)
                  _AppliedChip(
                    icon: Icons.card_giftcard_outlined,
                    label:
                        '${_appliedGiftCard!.code} applied — ${formatTaka(_appliedGiftCard!.balance)} available',
                    onRemove: _removeGiftCard,
                  )
                else
                  _InlineCodeField(
                    controller: _giftCardController,
                    hint: 'Enter gift card code',
                    buttonLabel: 'Check',
                    isLoading: _isValidatingGiftCard,
                    errorText: _giftCardError,
                    onSubmit: _applyGiftCard,
                    textCapitalization: TextCapitalization.characters,
                  ),
                const SizedBox(height: 32),
                _OrderSummaryCard(
                  cart: cart,
                  appliedCoupon: _appliedCoupon,
                  appliedGiftCard: _appliedGiftCard,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 24),
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _AddressPicker extends StatelessWidget {
  const _AddressPicker({
    required this.addresses,
    required this.selected,
    required this.useNewAddress,
    required this.onSelect,
    required this.onUseNewAddress,
    required this.manualForm,
  });

  final List<Address> addresses;
  final Address? selected;
  final bool useNewAddress;
  final ValueChanged<Address> onSelect;
  final VoidCallback onUseNewAddress;
  final Widget manualForm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    if (addresses.isEmpty) {
      return manualForm;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final address in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AddressOptionCard(
              address: address,
              selected: !useNewAddress && selected?.id == address.id,
              onTap: () => onSelect(address),
            ),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onUseNewAddress,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: useNewAddress ? brand.gold : theme.dividerColor,
                width: useNewAddress ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.add_location_alt_outlined, color: brand.gold),
                const SizedBox(width: 10),
                Text('Deliver to a new address', style: theme.textTheme.bodyLarge),
                const Spacer(),
                Radio<bool>(
                  value: true,
                  groupValue: useNewAddress,
                  onChanged: (_) => onUseNewAddress(),
                  activeColor: brand.gold,
                ),
              ],
            ),
          ),
        ),
        if (useNewAddress) ...[
          const SizedBox(height: 14),
          manualForm,
        ],
      ],
    );
  }
}

class _AddressOptionCard extends StatelessWidget {
  const _AddressOptionCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? brand.gold : theme.dividerColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.fullName,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Text('Default', style: TextStyle(color: brand.gold, fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.phone, style: theme.textTheme.bodyMedium),
                  Text(
                    '${address.street}, ${address.city}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: brand.gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualAddressForm extends StatelessWidget {
  const _ManualAddressForm({
    required this.fullNameController,
    required this.phoneController,
    required this.streetController,
    required this.cityController,
  });

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController streetController;
  final TextEditingController cityController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: fullNameController,
          decoration: const InputDecoration(labelText: 'Full name'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: streetController,
          decoration: const InputDecoration(labelText: 'Street address'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cityController,
          decoration: const InputDecoration(labelText: 'City'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 6),
        Text(
          'This address will be saved to your account for next time.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PaymentMethodPicker extends StatelessWidget {
  const _PaymentMethodPicker({required this.selected, required this.onChanged});
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return Column(
      children: [
        for (final method in PaymentMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(method),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == method ? brand.gold : theme.dividerColor,
                    width: selected == method ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(method.label, style: theme.textTheme.bodyLarge)),
                    Radio<PaymentMethod>(
                      value: method,
                      groupValue: selected,
                      onChanged: (v) => onChanged(v!),
                      activeColor: brand.gold,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InlineCodeField extends StatelessWidget {
  const _InlineCodeField({
    required this.controller,
    required this.hint,
    required this.buttonLabel,
    required this.isLoading,
    required this.onSubmit,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final String buttonLabel;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onSubmit;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(labelText: hint, errorText: errorText),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

class _AppliedChip extends StatelessWidget {
  const _AppliedChip({required this.icon, required this.label, required this.onRemove});
  final IconData icon;
  final String label;
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
          Icon(icon, color: brand.sage, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: brand.sage, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cart, this.appliedCoupon, this.appliedGiftCard});
  final Cart cart;
  final Coupon? appliedCoupon;
  final GiftCardBalance? appliedGiftCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final previewDiscount = appliedCoupon?.previewDiscount(cart.subtotal) ?? 0;
    final estimatedAfterCoupon =
        (cart.subtotal - previewDiscount).clamp(0, double.infinity).toDouble();
    final estimatedGiftCardApplied = appliedGiftCard != null
        ? (appliedGiftCard!.balance < estimatedAfterCoupon
            ? appliedGiftCard!.balance
            : estimatedAfterCoupon)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brand.roseSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: theme.textTheme.bodyLarge),
              Text(formatTaka(cart.subtotal), style: theme.textTheme.bodyLarge),
            ],
          ),
          if (previewDiscount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupon discount', style: TextStyle(color: brand.sage)),
                Text('-${formatTaka(previewDiscount)}', style: TextStyle(color: brand.sage)),
              ],
            ),
          ],
          if (estimatedGiftCardApplied > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gift card (est.)', style: TextStyle(color: brand.sage)),
                Text('-${formatTaka(estimatedGiftCardApplied)}', style: TextStyle(color: brand.sage)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Delivery fee'),
              Text('Calculated by server'),
            ],
          ),
          const Divider(height: 24),
          Text(
            'Free delivery on orders over ৳2,000. Final total (including any discounts and gift card credit) is confirmed on the order confirmation screen.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
