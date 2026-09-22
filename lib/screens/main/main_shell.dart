// lib/screens/main/main_shell.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../shopping/cart_scope.dart';
import '../../shopping/wishlist_scope.dart';
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
  bool _loadedCart = false;
  bool _loadedWishlist = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedCart) {
      _loadedCart = true;
      CartScope.of(context, listen: false).bootstrap();
    }
    if (!_loadedWishlist) {
      _loadedWishlist = true;
      WishlistScope.of(context, listen: false).bootstrap();
    }
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final auth = AuthScope.of(context, listen: false);
    try {
      final list = await auth.notifications();
      final unread = list.where((n) => n['is_read'] != true && n['read'] != true).length;
      if (mounted) setState(() => _unreadNotifications = unread);
    } catch (_) {}
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToTab: _onTabSelected,
            unreadNotifications: _unreadNotifications,
          ),
          ActivityScreen(auth: auth),
          NotificationsScreen(auth: auth),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        notificationCount: _unreadNotifications,
      ),
    );
  }
}