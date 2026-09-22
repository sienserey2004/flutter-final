// lib/widgets/delivery_method_tile.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/shipping_option.dart';

class DeliveryMethodTile extends StatelessWidget {
  const DeliveryMethodTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    required this.afterDiscount,
  });
  final ShippingOption option;
  final bool selected;
  final VoidCallback onTap;
  final double afterDiscount;

  @override
  Widget build(BuildContext context) {
    final feeText = option.effectiveFee == 0
        ? 'FREE'
        : formatPrice(option.effectiveFee);
    final feeColor = option.effectiveFee == 0
        ? AppColors.primary
        : AppColors.textPrimary;
    final needsMore = option.freeOver != null &&
        option.effectiveFee > 0 &&
        afterDiscount < option.freeOver!;
    final remaining =
        needsMore ? (option.freeOver! - afterDiscount) : 0.0;

    return Semantics(
      selected: selected,
      label:
          '${option.name}, ${option.etaLabel}, ${option.effectiveFee == 0 ? 'free' : formatPrice(option.effectiveFee)}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: selected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (option.etaLabel.isNotEmpty)
                      Text(option.etaLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    if (needsMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Add ${formatPrice(remaining)} more for free delivery',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.warning),
                        ),
                      ),
                  ],
                ),
              ),
              Text(feeText,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: feeColor)),
            ],
          ),
        ),
      ),
    );
  }
}