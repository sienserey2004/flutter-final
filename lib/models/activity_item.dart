// lib/models/activity_item.dart
import 'package:flutter/material.dart';

import '../core/format.dart';

class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
    this.createdAt,
    this.status = '',
    this.amount,
    this.isPositive = true,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
  final DateTime? createdAt;
  final String status;
  final String? amount;
  final bool isPositive;

  factory ActivityItem.fromOrder(Map<String, dynamic> json) {
    final createdAt = parseServerDate(json['created_at']?.toString());
    final status = (json['status'] ?? 'Pending').toString();
    final total = json['total_amount'];
    return ActivityItem(
      title: 'Order #${json['order_id'] ?? ''}',
      subtitle: '$status · ${json['item_count'] ?? 0} items',
      timeLabel: formatOrderDateTime(createdAt),
      icon: Icons.shopping_bag_outlined,
      createdAt: createdAt,
      status: status,
      amount: total == null ? null : formatPrice(num.tryParse(total.toString())),
      isPositive: false,
    );
  }
}
