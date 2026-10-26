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

}
