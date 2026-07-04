import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/misc.dart';
import '../../core/providers.dart';
import '../../core/theme/app_brand_colors.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/async_states.dart';
import 'addresses_providers.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(myAddressesProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: addressesAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(myAddressesProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyView(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              subtitle: 'Add an address to speed up checkout next time.',
              actionLabel: 'Add Address',
              onAction: () => showAddressFormSheet(context, ref),
            );
          }
          return RefreshIndicator(
            color: brand.gold,
            onRefresh: () async => ref.invalidate(myAddressesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _AddressTile(address: addresses[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddressFormSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  const _AddressTile({required this.address});
  final Address address;

  Future<void> _setDefault(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(usersRepositoryProvider).updateAddress(
            address.id!,
            Address(
              id: address.id,
              fullName: address.fullName,
              phone: address.phone,
              street: address.street,
              city: address.city,
              district: address.district,
              postalCode: address.postalCode,
              isDefault: true,
            ),
          );
      ref.invalidate(myAddressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('This will remove "${address.fullName}, ${address.street}" from your saved addresses.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(usersRepositoryProvider).deleteAddress(address.id!);
      ref.invalidate(myAddressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brand = context.brand;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: address.isDefault ? brand.gold : theme.dividerColor,
          width: address.isDefault ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  address.fullName,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (address.isDefault)
                AppBadge.soft(text: 'DEFAULT', color: brand.gold, textColor: brand.gold),
            ],
          ),
          const SizedBox(height: 6),
          Text(address.phone, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 2),
          Builder(builder: (context) {
            final district = address.district;
            final postalCode = address.postalCode;
            final line = [
              address.street,
              if (district != null && district.isNotEmpty) district,
              address.city,
              if (postalCode != null && postalCode.isNotEmpty) postalCode,
            ].join(', ');
            return Text(line, style: theme.textTheme.bodyMedium);
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!address.isDefault)
                TextButton(
                  onPressed: () => _setDefault(context, ref),
                  child: const Text('Set as default'),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => showAddressFormSheet(context, ref, existing: address),
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () => _delete(context, ref),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet form to add a new address or edit [existing]. Shared by
/// the Addresses screen and Checkout ("add a new address" flow) so both
/// stay in sync with the same validation and save logic.
Future<void> showAddressFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Address? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddressFormSheet(existing: existing),
  );
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet({this.existing});
  final Address? existing;

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _fullNameController =
      TextEditingController(text: widget.existing?.fullName ?? '');
  late final _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
  late final _streetController = TextEditingController(text: widget.existing?.street ?? '');
  late final _cityController = TextEditingController(text: widget.existing?.city ?? '');
  late final _districtController =
      TextEditingController(text: widget.existing?.district ?? '');
  late final _postalCodeController =
      TextEditingController(text: widget.existing?.postalCode ?? '');
  late bool _isDefault = widget.existing?.isDefault ?? false;

  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final address = Address(
      id: widget.existing?.id,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      postalCode:
          _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      isDefault: _isDefault,
    );

    try {
      final repo = ref.read(usersRepositoryProvider);
      if (_isEditing) {
        await repo.updateAddress(widget.existing!.id!, address);
      } else {
        await repo.addAddress(address);
      }
      ref.invalidate(myAddressesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit Address' : 'Add Address',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'District (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Postal code (optional)'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Set as default address'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Add Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
