// lib/models/app_notification.dart
import 'package:flutter/material.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.icon = Icons.notifications_outlined,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;

  /// Mutable so "mark as read" works without extra plumbing.
  bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: (json['notification_id'] ?? json['id']).toString(),
        title: (json['title'] ?? 'Notification').toString(),
        body: (json['message'] ?? json['body'] ?? '').toString(),
        timeLabel: (json['created_at'] ?? '').toString(),
        isRead: json['is_read'] == true,
      );

  static List<AppNotification> samples() => [
        AppNotification(
          id: 'n1',
          title: 'Payment received',
          body: 'Your payment of \$120.00 was processed successfully.',
          timeLabel: '2m ago',
          icon: Icons.check_circle_outline_rounded,
        ),
        AppNotification(
          id: 'n2',
          title: 'New message',
          body: 'Alex replied to your support request.',
          timeLabel: '1h ago',
          icon: Icons.mark_email_unread_outlined,
        ),
        AppNotification(
          id: 'n3',
          title: 'Weekly summary ready',
          body: 'Your activity report for last week is available.',
          timeLabel: 'Yesterday',
          icon: Icons.insights_rounded,
          isRead: true,
        ),
        AppNotification(
          id: 'n4',
          title: 'Security tip',
          body: 'Enable two-factor authentication to keep your account safe.',
          timeLabel: '3d ago',
          icon: Icons.lock_outline_rounded,
          isRead: true,
        ),
      ];
}
