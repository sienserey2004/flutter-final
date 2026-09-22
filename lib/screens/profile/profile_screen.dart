// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/session_actions.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/settings_item.dart';
import '../orders/addresses_screen.dart';
import '../orders/order_history_screen.dart';
import '../settings/account_settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (user != null) ProfileHeader(user: user),

            const SizedBox(height: AppSpacing.xxl),

            SettingsSection(
              children: [
                SettingsItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: 'Update your name, email and phone',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                ),
                SettingsItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'My Orders',
                  subtitle: 'View your order history',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                  ),
                ),
                SettingsItem(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: 'Manage delivery addresses',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddressesScreen()),
                  ),
                ),
                SettingsItem(
                  icon: Icons.settings_outlined,
                  title: 'Account Settings',
                  subtitle: 'Password, preferences and security',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            SettingsSection(
              children: [
                SettingsItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isDestructive: true,
                  showArrow: false,
                  onTap: () => confirmAndLogout(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}