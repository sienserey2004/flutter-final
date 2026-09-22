import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';

class PriceText extends StatelessWidget {
  final double price;
  final double? compareAtPrice;
  final int? discountPercent;
  final double size;

  const PriceText({
    super.key,
    required this.price,
    this.compareAtPrice,
    this.discountPercent,
    this.size = 15,
  });

  @override
  Widget build(BuildContext context) {
    final hasCompare = compareAtPrice != null && compareAtPrice! > price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          formatPrice(price),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (hasCompare) ...[
          const SizedBox(width: 6),
          Text(
            formatPrice(compareAtPrice),
            style: TextStyle(
              fontSize: size - 2,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
        if (discountPercent != null && discountPercent! > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
            child: Text(
              '−$discountPercent%',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}