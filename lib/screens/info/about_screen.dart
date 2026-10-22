// lib/screens/info/about_screen.dart
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/settings_item.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const version = '1.0.0';

  static const _features = [
    (Icons.category_outlined, 'Browse by category, brand and skin concern'),
    (Icons.tune_rounded, 'Search, filter and sort the full catalogue'),
    (Icons.favorite_border_rounded, 'Save favourites to your wishlist'),
    (Icons.qr_code_2_rounded, 'Pay cash on delivery or with KHQR · Bakong'),
    (Icons.receipt_long_outlined, 'Track orders and delivery status'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            const Center(child: AppLogo(size: 80)),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Aurea Skin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Care that glows from within',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Aurea Skin is a skincare shopping app for Cambodia. It helps '
              'you discover trusted products, understand their ingredients, '
              'and order them for delivery to your door.',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsSection(
              title: 'What you can do',
              children: [
                for (final (icon, label) in _features)
                  SettingsItem(icon: icon, title: label, showArrow: false),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const SettingsSection(
              title: 'App',
              children: [
                SettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: version,
                  showArrow: false,
                ),
                SettingsItem(
                  icon: Icons.code_rounded,
                  title: 'Built with',
                  subtitle: 'Flutter app · Flask REST API',
                  showArrow: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              '© 2026 Aurea Skin. Final project — Mobile Application Development.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
