// lib/models/order_status_event.dart
import '../core/format.dart';

class OrderStatusEvent {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime? createdAt;

  const OrderStatusEvent({
    this.fromStatus,
    required this.toStatus,
    this.note,
    this.createdAt,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) =>
      OrderStatusEvent(
        fromStatus: json['from_status'] as String?,
        toStatus: json['to_status'] as String? ?? 'Pending',
        note: json['note'] as String?,
        createdAt: parseServerDate(json['created_at'] as String?),
      );
}