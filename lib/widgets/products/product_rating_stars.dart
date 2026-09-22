import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ProductRatingStars extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;

  const ProductRatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final semantics = reviewCount == null
        ? '${rating.toStringAsFixed(1)} out of 5 stars'
        : '${rating.toStringAsFixed(1)} out of 5 stars, $reviewCount reviews';

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Icon(
              _iconFor(i),
              size: size,
              color: AppColors.warning,
            ),
          if (reviewCount != null) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: size - 2,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(int i) {
    final value = rating - i;
    if (value >= 0.75) return Icons.star_rounded;
    if (value >= 0.25) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }
}