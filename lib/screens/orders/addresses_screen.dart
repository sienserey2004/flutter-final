// lib/screens/orders/addresses_screen.dart
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../models/address.dart';
import '../../orders/address_repository.dart';
import '../../widgets/address_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/state_views.dart';
import 'address_form_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late final AddressRepository _repo;
  List<Address> _addresses = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = AddressRepository(AuthScope.of(context, listen: false).api);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.list();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load addresses.';
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Address? address}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddressFormScreen(address: address),
    ));
    _load();
  }

  Future<void> _delete(Address a) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Delete this address?',
      message: 'This address will be permanently removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true) return;
    try {
      await _repo.delete(a.addressId);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete address.')));
    }
  }

  Future<void> _makeDefault(Address a) async {
    try {
      await _repo.makeDefault(a.addressId);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update default.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Addresses')),
      body: Column(children: [
        if (_error != null) ErrorBanner(message: _error!, onRetry: _load),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _addresses.isEmpty
                  ? EmptyState(
                      icon: Icons.location_on_outlined,
                      title: 'No addresses yet',
                      message: 'Add a delivery address to get started.',
                      action: AppButton(
                        label: 'Add address',
                        onPressed: () => _openForm(),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _addresses.length,
                      itemBuilder: (_, i) {
                        final a = _addresses[i];
                        return AddressCard(
                          address: a,
                          onEdit: () => _openForm(address: a),
                          onMakeDefault: () => _makeDefault(a),
                          onDelete: () => _delete(a),
                        );
                      },
                    ),
        ),
      ]),
      bottomNavigationBar: _addresses.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AppButton(
                  label: 'Add address',
                  onPressed: () => _openForm(),
                ),
              ),
            )
          : null,
    );
  }
}
