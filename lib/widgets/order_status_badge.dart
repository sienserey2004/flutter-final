// lib/widgets/order_status_badge.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class OrderStatusStyle {
  final Color fg;
  final Color bg;
  final IconData? icon;
  const OrderStatusStyle(this.fg, this.bg, [this.icon]);
}

const kOrderStatusStyles = <String, OrderStatusStyle>{
  'Pending':    OrderStatusStyle(AppColors.warning, AppColors.warningSoft, Icons.schedule),
  'Processing': OrderStatusStyle(AppColors.primary, AppColors.primarySoft, Icons.autorenew),
  'Shipped':    OrderStatusStyle(AppColors.primary, AppColors.primarySoft, Icons.local_shipping),
  'Delivered':  OrderStatusStyle(AppColors.success, AppColors.successSoft, Icons.check_circle),
  'Cancelled':  OrderStatusStyle(AppColors.error,   AppColors.errorSoft,   Icons.cancel),
};

OrderStatusStyle orderStatusStyle(String status) =>
    kOrderStatusStyles[status] ??
    const OrderStatusStyle(AppColors.textTertiary, AppColors.surfaceMuted);

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = orderStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (s.icon != null) ...[
          Icon(s.icon, size: 12, color: s.fg),
          const SizedBox(width: 4),
        ],
        Text(status,
            style: TextStyle(
                color: s.fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}