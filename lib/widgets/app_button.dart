// lib/widgets/app_button.dart
import 'package:flutter/material.dart';

import '../core/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

/// One button to rule them all: consistent height, radius, loading and
/// disabled states across every screen.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    final Color spinnerColor = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.destructive => Colors.white,
      AppButtonVariant.secondary => AppColors.primary,
      AppButtonVariant.ghost => AppColors.primary,
    };

    final Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.destructive =>
        FilledButton(
          onPressed: disabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: variant == AppButtonVariant.destructive
                ? AppColors.error
                : AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: (variant == AppButtonVariant.destructive
                    ? AppColors.error
                    : AppColors.primary)
                .withAlpha(110),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.surface,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: content,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(kMinTouchTarget),
          ),
          child: content,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}