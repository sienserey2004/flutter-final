// lib/models/activity_item.dart
import 'package:flutter/material.dart';

class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
    this.amount,
    this.isPositive = true,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
  final String? amount;
  final bool isPositive;

  factory ActivityItem.fromOrder(Map<String, dynamic> json) => ActivityItem(
        title: 'Order #${json['order_id'] ?? ''}',
        subtitle: '${json['status'] ?? 'Pending'} · ${json['item_count'] ?? 0} items',
        timeLabel: (json['created_at'] ?? '').toString(),
        icon: Icons.shopping_bag_outlined,
        amount: json['total_amount'] == null ? null : '\$${json['total_amount']}',
        isPositive: false,
      );

  static const List<ActivityItem> all = [
    ActivityItem(
      title: 'Invoice #1042',
      subtitle: 'Paid to Acme Studio',
      timeLabel: 'Today, 09:24',
      icon: Icons.receipt_long_outlined,
      amount: '-\$120.00',
      isPositive: false,
    ),
    ActivityItem(
      title: 'Payment received',
      subtitle: 'From Jordan Lee',
      timeLabel: 'Today, 08:02',
      icon: Icons.arrow_downward_rounded,
      amount: '+\$340.00',
    ),
    ActivityItem(
      title: 'Subscription renewed',
      subtitle: 'Pro plan · monthly',
      timeLabel: 'Yesterday',
      icon: Icons.autorenew_rounded,
      amount: '-\$19.00',
      isPositive: false,
    ),
    ActivityItem(
      title: 'Refund issued',
      subtitle: 'Order #88213',
      timeLabel: 'Mon, 14:11',
      icon: Icons.undo_rounded,
      amount: '+\$42.50',
    ),
    ActivityItem(
      title: 'New team member',
      subtitle: 'Sam joined your workspace',
      timeLabel: 'Sun, 18:40',
      icon: Icons.person_add_alt_1_outlined,
    ),
  ];
}
