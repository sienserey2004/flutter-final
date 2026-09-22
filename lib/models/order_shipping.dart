// lib/models/order_shipping.dart
import '../core/format.dart';

class OrderShipping {
  final String? recipientName;
  final String? phone;
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? status;
  final String? carrier;
  final String? trackingNumber;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const OrderShipping({
    this.recipientName,
    this.phone,
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.status,
    this.carrier,
    this.trackingNumber,
    this.shippedAt,
    this.deliveredAt,
  });

  String get oneLine => [
        line1, line2, city, state, postalCode, country,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

  factory OrderShipping.fromJson(Map<String, dynamic> json) => OrderShipping(
        recipientName: json['recipient_name'] as String?,
        phone: json['phone'] as String?,
        line1: json['line1'] as String?,
        line2: json['line2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        postalCode: json['postal_code'] as String?,
        country: json['country'] as String?,
        status: json['status'] as String?,
        carrier: json['carrier'] as String?,
        trackingNumber: json['tracking_number'] as String?,
        shippedAt: parseServerDate(json['shipped_at'] as String?),
        deliveredAt: parseServerDate(json['delivered_at'] as String?),
      );
}