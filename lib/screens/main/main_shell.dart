// lib/screens/main/main_shell.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../core/session_actions.dart';
import '../../widgets/bottom_navigation.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'activity_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final auth = AuthScope.of(context, listen: false);
    if (!auth.isAuthenticated) {
      _unreadNotifications = 0;
      return;
    }
    try {
      final list = await auth.notifications();
      final unread = list.where((n) => n['is_read'] != true && n['read'] != true).length;
      if (mounted) setState(() => _unreadNotifications = unread);
    } catch (_) {}
  }

  Future<void> _onTabSelected(int index) async {
    // Every tab except Home belongs to an account.
    if (index != 0 && !await requireLogin(context)) return;
    if (mounted) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final signedIn = auth.isAuthenticated;
    final index = signedIn ? _currentIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          HomeScreen(
            onNavigateToTab: _onTabSelected,
            unreadNotifications: _unreadNotifications,
          ),
          if (signedIn) ActivityScreen(auth: auth) else const SizedBox.shrink(),
          if (signedIn) NotificationsScreen(auth: auth) else const SizedBox.shrink(),
          if (signedIn) const ProfileScreen() else const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: index,
        onTap: _onTabSelected,
        notificationCount: _unreadNotifications,
      ),
    );
  }
}