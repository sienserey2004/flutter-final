// lib/screens/orders/address_form_screen.dart
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../models/address.dart';
import '../../orders/address_repository.dart';
import '../../widgets/address_fields.dart';
import '../../widgets/app_button.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/state_views.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.address});
  final Address? address;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late final AddressRepository _repo;
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController(text: 'Cambodia');
  String? _label;
  bool _isDefault = false;
  bool _busy = false;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _repo = AddressRepository(AuthScope.of(context, listen: false).api);
    final a = widget.address;
    if (a != null) {
      _recipient.text = a.recipientName;
      _phone.text = a.phone;
      _line1.text = a.line1;
      _line2.text = a.line2 ?? '';
      _city.text = a.city;
      _state.text = a.state ?? '';
      _postal.text = a.postalCode ?? '';
      _country.text = a.country;
      _label = a.label;
      _isDefault = a.isDefault;
    } else {
      final u = AuthScope.of(context, listen: false).user;
      _recipient.text = u?.name ?? '';
      _phone.text = u?.phone ?? '';
    }
    for (final c in [_recipient, _phone, _line1, _line2, _city, _state, _postal, _country]) {
      c.addListener(() {
        if (!_dirty && mounted) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_recipient, _phone, _line1, _line2, _city, _state, _postal, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Discard this address?',
      message: 'Your changes will be lost.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    return ok == true;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final draft = draftFromControllers(
      recipient: _recipient,
      phone: _phone,
      line1: _line1,
      line2: _line2,
      city: _city,
      state: _state,
      postal: _postal,
      country: _country,
      label: _label,
      isDefault: _isDefault,
    );
    try {
      if (widget.address == null) {
        await _repo.create(draft);
      } else {
        await _repo.update(widget.address!.addressId, draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _confirmDiscard()) {
          if (!mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.address == null ? 'New address' : 'Edit address'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmDiscard()) {
                if (!mounted) return;
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ErrorBanner(message: _error!),
            _labelChips(),
            const SizedBox(height: 16),
            AddressFields(
              recipient: _recipient,
              phone: _phone,
              line1: _line1,
              line2: _line2,
              city: _city,
              state: _state,
              postal: _postal,
              country: _country,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (v) => setState(() {
                _isDefault = v;
                _dirty = true;
              }),
              title: const Text('Set as default'),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AppButton(
              label: widget.address == null ? 'Save address' : 'Update address',
              isLoading: _busy,
              onPressed: _busy ? null : _save,
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelChips() {
    const options = ['Home', 'Work', 'Other'];
    return Wrap(
      spacing: 8,
      children: options.map((o) {
        final selected = _label == o;
        return ChoiceChip(
          label: Text(o),
          selected: selected,
          onSelected: (_) => setState(() {
            _label = selected ? null : o;
            _dirty = true;
          }),
        );
      }).toList(),
    );
  }
}
