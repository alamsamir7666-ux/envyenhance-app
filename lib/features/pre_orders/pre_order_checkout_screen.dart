import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/product.dart';
import '../../core/models/order.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/utils/formatters.dart';

class PreOrderCheckoutScreen extends ConsumerStatefulWidget {
  const PreOrderCheckoutScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<PreOrderCheckoutScreen> createState() => _PreOrderCheckoutScreenState();
}

class _PreOrderCheckoutScreenState extends ConsumerState<PreOrderCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _senderCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String _paymentMethod = 'bkash';
  int _quantity = 1;
  bool _loading = false;
  String? _error;

  double get _basePrice => widget.product.discountPrice ?? widget.product.price;
  double get _discountedPrice => (_basePrice * 0.95 * 100).roundToDouble() / 100;
  double get _savings => (_basePrice - _discountedPrice);
  bool get _isDhaka => _cityCtrl.text.toLowerCase().contains('dhaka');
  double get _deliveryCharge => _cityCtrl.text.isEmpty ? 80 : (_isDhaka ? 80 : 120);
  double get _total => (_discountedPrice * _quantity) + _deliveryCharge;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _streetCtrl.dispose();
    _cityCtrl.dispose(); _districtCtrl.dispose(); _senderCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(preOrdersRepositoryProvider);
      final result = await repo.place(
        productId: widget.product.id,
        quantity: _quantity,
        shippingAddress: ShippingAddress(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          street: _streetCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          postalCode: '',
        ),
        paymentMethod: _paymentMethod,
        senderNumber: _senderCtrl.text.trim().isEmpty ? null : _senderCtrl.text.trim(),
        whatsappPhone: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
      );
      if (mounted) context.pushReplacement('/pre-orders/${result.trackingId}');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Order Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: brand.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: brand.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_offer_outlined, size: 14, color: brand.gold),
                      const SizedBox(width: 4),
                      Text('5% pre-order discount applied',
                          style: TextStyle(fontSize: 12, color: brand.gold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Price: ${formatTaka(_discountedPrice)} (save ${formatTaka(_savings)})',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quantity
            Row(
              children: [
                Text('Quantity', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity', style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Delivery address
            Text('Delivery Address', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _field(_nameCtrl, 'Full Name', required: true),
            _field(_phoneCtrl, 'Phone Number', required: true, keyboardType: TextInputType.phone),
            _field(_streetCtrl, 'Street Address', required: true),
            _field(_cityCtrl, 'City', required: true, onChanged: (_) => setState(() {})),
            _field(_districtCtrl, 'District'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 14, color: brand.gold),
                const SizedBox(width: 4),
                Text('Delivery charge: ${formatTaka(_deliveryCharge)}',
                    style: TextStyle(fontSize: 12, color: brand.gold)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Payment
            Text('Payment Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _payBtn('bkash', 'bKash', Colors.pink),
                const SizedBox(width: 10),
                _payBtn('nagad', 'Nagad', Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            _field(_senderCtrl,
              '${_paymentMethod == 'bkash' ? 'bKash' : 'Nagad'} sending number',
              required: true,
              keyboardType: TextInputType.phone,
            ),
            _field(_whatsappCtrl, 'WhatsApp number (optional for updates)',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            // Order summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _summaryRow('Subtotal', formatTaka(_discountedPrice * _quantity), theme),
                  _summaryRow('Delivery', formatTaka(_deliveryCharge), theme),
                  const Divider(),
                  _summaryRow('Total', formatTaka(_total), theme, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
              ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: brand.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Place Pre-Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _payBtn(String value, String label, Color color) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : null,
            border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? color : null,
                )),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, ThemeData theme, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700) : theme.textTheme.bodyMedium),
          Text(value, style: bold ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700) : theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
