// lib/widgets/address_fields.dart
import 'package:flutter/material.dart';
import '../models/address.dart';

/// Shared by the checkout "new address" branch and the address form.
class AddressFields extends StatelessWidget {
  const AddressFields({
    super.key,
    required this.recipient,
    required this.phone,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.postal,
    required this.country,
    this.recipientError,
    this.phoneError,
    this.line1Error,
    this.cityError,
  });

  final TextEditingController recipient, phone, line1, line2,
      city, state, postal, country;
  final String? recipientError, phoneError, line1Error, cityError;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        controller: recipient,
        decoration: InputDecoration(
          labelText: 'Recipient name *',
          errorText: recipientError,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: phone,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Phone *',
          errorText: phoneError,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: line1,
        decoration: InputDecoration(
          labelText: 'Address line 1 *',
          errorText: line1Error,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: line2,
        decoration: const InputDecoration(labelText: 'Address line 2'),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: TextField(
            controller: city,
            decoration: InputDecoration(
              labelText: 'City *',
              errorText: cityError,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: state,
            decoration: const InputDecoration(labelText: 'State'),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: TextField(
            controller: postal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Postal code'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: country,
            decoration: const InputDecoration(labelText: 'Country'),
          ),
        ),
      ]),
    ]);
  }
}

AddressDraft draftFromControllers({
  required TextEditingController recipient,
  required TextEditingController phone,
  required TextEditingController line1,
  required TextEditingController line2,
  required TextEditingController city,
  required TextEditingController state,
  required TextEditingController postal,
  required TextEditingController country,
  String? label,
  bool isDefault = false,
}) =>
    AddressDraft(
      label: label,
      recipientName: recipient.text.trim(),
      phone: phone.text.trim(),
      line1: line1.text.trim(),
      line2: line2.text.trim().isEmpty ? null : line2.text.trim(),
      city: city.text.trim(),
      state: state.text.trim().isEmpty ? null : state.text.trim(),
      postalCode: postal.text.trim().isEmpty ? null : postal.text.trim(),
      country: country.text.trim().isEmpty ? 'Cambodia' : country.text.trim(),
      isDefault: isDefault,
    );