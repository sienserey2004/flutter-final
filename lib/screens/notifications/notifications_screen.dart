import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../models/app_notification.dart';
import '../../widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.auth});
  final AuthController auth;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<AppNotification> _notifications = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.auth.notifications();
      if (mounted) setState(() => _notifications = data.map(AppNotification.fromJson).toList());
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _markAll() async {
    try { await widget.auth.markAllNotificationsRead(); await _load(); }
    catch (e) { if (mounted) setState(() => _error = e.toString()); }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    try { await widget.auth.markNotificationRead(int.parse(notification.id)); await _load(); }
    catch (e) { if (mounted) setState(() => _error = e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((item) => !item.isRead).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.md), child: Row(children: [
          const Expanded(child: Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          if (unread > 0) TextButton.icon(onPressed: _markAll, icon: const Icon(Icons.done_all_rounded, size: 18), label: const Text('Mark all read')),
        ])),
        Expanded(child: _body()),
      ])),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingIndicator(message: 'Loading notifications…');
    if (_error != null) return ErrorStateView(message: _error!, onRetry: _load);
    if (_notifications.isEmpty) return const EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications', message: "You're all caught up. New updates will show here.");
    return RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xxl), itemCount: _notifications.length, separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm), itemBuilder: (_, index) => _NotificationTile(notification: _notifications[index], onTap: () => _markRead(_notifications[index]))));
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Material(color: unread ? AppColors.primarySoft : AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.lg), child: Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: unread ? AppColors.primary.withAlpha(70) : AppColors.border)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const CircleAvatar(backgroundColor: AppColors.surface, child: Icon(Icons.notifications_outlined, color: AppColors.primary)),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(notification.title, style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w600, color: AppColors.textPrimary)), const SizedBox(height: 4), Text(notification.body, style: const TextStyle(color: AppColors.textSecondary)), const SizedBox(height: AppSpacing.sm), Text(notification.timeLabel, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary))])),
      if (unread) const Padding(padding: EdgeInsets.only(left: 8), child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary)),
    ]))));
  }
}
