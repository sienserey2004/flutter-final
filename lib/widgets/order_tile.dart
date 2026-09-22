// lib/widgets/order_tile.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/order.dart';
import 'order_status_badge.dart';

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, this.onTap});
  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final paymentLabel = order.payment?.method ?? 'Cash';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('#${order.orderId}',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                OrderStatusBadge(order.status),
              ]),
              const SizedBox(height: 6),
              Text(formatOrderDate(order.createdAt),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Text(
                    '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · $paymentLabel',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Text(formatPrice(order.totalAmount),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    color: AppColors.textTertiary, size: 20),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}