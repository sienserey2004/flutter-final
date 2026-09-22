// lib/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// The persistent bottom navigation: the four main areas of the app only.
/// Auth screens, Edit Profile, Account Settings and Logout never appear here.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          height: 68,
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primarySoft,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: notificationCount > 0,
                label: Text('$notificationCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: notificationCount > 0,
                label: Text('$notificationCount'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Notifications',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}