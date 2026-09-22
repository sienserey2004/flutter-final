// lib/widgets/order_item_tile.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/order_item.dart';

class OrderItemTile extends StatelessWidget {
  const OrderItemTile({super.key, required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: url == null
                ? Container(
                    color: AppColors.surfaceMuted,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textTertiary),
                  )
                : Image.network(url, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (item.displayVariantLabel != null)
                Text(item.displayVariantLabel!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              Text('${formatPrice(item.price)} × ${item.quantity}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(formatPrice(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}