import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

enum ProductBadgeKind { sale, isNew, outOfStock, info }

class ProductBadge extends StatelessWidget {
  final String label;
  final ProductBadgeKind kind;

  const ProductBadge({super.key, required this.label, this.kind = ProductBadgeKind.info});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (kind) {
      case ProductBadgeKind.sale:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        break;
      case ProductBadgeKind.isNew:
        bg = AppColors.primary.withOpacity(0.12);
        fg = AppColors.primary;
        break;
      case ProductBadgeKind.outOfStock:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        break;
      case ProductBadgeKind.info:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textPrimary;
        break;
    }

    final semantics = kind == ProductBadgeKind.sale
        ? 'On sale, $label'
        : label;

    return Semantics(
      label: semantics,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}