// lib/models/address.dart
class Address {
  final int addressId;
  final String? label;
  final String recipientName;
  final String phone;
  final String line1;
  final String? line2;
  final String? state;
  final String? postalCode;
  final String city;
  final String country;
  final bool isDefault;
  final String oneLine;

  const Address({
    required this.addressId,
    this.label,
    required this.recipientName,
    required this.phone,
    required this.line1,
    this.line2,
    this.state,
    this.postalCode,
    required this.city,
    this.country = 'Cambodia',
    this.isDefault = false,
    this.oneLine = '',
  });

  Address copyWith({
    int? addressId,
    String? label,
    String? recipientName,
    String? phone,
    String? line1,
    String? line2,
    String? state,
    String? postalCode,
    String? city,
    String? country,
    bool? isDefault,
    String? oneLine,
  }) =>
      Address(
        addressId: addressId ?? this.addressId,
        label: label ?? this.label,
        recipientName: recipientName ?? this.recipientName,
        phone: phone ?? this.phone,
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        state: state ?? this.state,
        postalCode: postalCode ?? this.postalCode,
        city: city ?? this.city,
        country: country ?? this.country,
        isDefault: isDefault ?? this.isDefault,
        oneLine: oneLine ?? this.oneLine,
      );

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json['address_id'] as int,
        label: json['label'] as String?,
        recipientName: json['recipient_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        line1: json['line1'] as String? ?? '',
        line2: json['line2'] as String?,
        state: json['state'] as String?,
        postalCode: json['postal_code'] as String?,
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? 'Cambodia',
        isDefault: (json['is_default'] as bool?) ?? false,
        oneLine: json['one_line'] as String? ?? '',
      );
}

/// The payload an address form submits. Order endpoint calls this an "address"
/// field (`line1` here) — the mismatch is handled in the checkout controller.
class AddressDraft {
  final String? label;
  final String recipientName;
  final String phone;
  final String line1;
  final String? line2;
  final String? state;
  final String? postalCode;
  final String city;
  final String country;
  final bool isDefault;

  const AddressDraft({
    this.label,
    required this.recipientName,
    required this.phone,
    required this.line1,
    this.line2,
    this.state,
    this.postalCode,
    required this.city,
    this.country = 'Cambodia',
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        if (label != null && label!.isNotEmpty) 'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'line1': line1,
        if (line2 != null && line2!.isNotEmpty) 'line2': line2,
        if (state != null && state!.isNotEmpty) 'state': state,
        if (postalCode != null && postalCode!.isNotEmpty) 'postal_code': postalCode,
        'city': city,
        'country': country.isEmpty ? 'Cambodia' : country,
        'is_default': isDefault,
      };
}