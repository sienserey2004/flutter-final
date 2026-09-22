// lib/widgets/settings_item.dart
import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// A single menu row: icon + title (+ subtitle) + trailing arrow or switch.
class SettingsItem extends StatelessWidget {
  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showArrow = true,
    this.isDestructive = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;
  final bool isDestructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        isDestructive ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouchTarget - 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppColors.errorSoft
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: isDestructive ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: enabled ? accent : AppColors.textTertiary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (showArrow)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card wrapper that visually groups [SettingsItem]s into a section.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, indent: 66),
              ],
            ],
          ),
        ),
      ],
    );
  }
}