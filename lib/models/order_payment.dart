// lib/models/order_payment.dart
import '../core/format.dart';

class OrderPayment {
  final String method;
  final double amount;
  final String status;
  final DateTime? paidAt;

  const OrderPayment({
    required this.method,
    required this.amount,
    required this.status,
    this.paidAt,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) => OrderPayment(
        method: json['method'] as String? ?? 'Cash',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'Pending',
        paidAt: parseServerDate(json['paid_at'] as String?),
      );
}