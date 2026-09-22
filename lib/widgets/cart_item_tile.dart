import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/image_url.dart';
import '../models/cart_item.dart';
import 'products/price_text.dart';
import 'products/product_image_tile.dart';
import 'quantity_stepper.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.pending,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onTap,
  });

  final CartItem item;
  final bool pending;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = item.variant;
    final imageUrl = resolveImageUrl(v.image);
    final stock = v.stock;
    final outOfStock = stock == 0;
    final lowStock = stock > 0 && stock <= 3;

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Hero(
              tag: 'cart-${v.variantId}',
              child: SizedBox(
                width: 72,
                height: 72,
                child: ProductImageTile(
                  url: imageUrl,
                  semanticLabel: item.productName,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.brandName != null && item.brandName!.isNotEmpty)
                  Text(
                    item.brandName!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (v.label != null && v.label!.isNotEmpty)
                  Text(v.label!, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                PriceText(price: v.price, compareAtPrice: v.compareAtPrice),
                if (lowStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Only $stock left',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                    ),
                  ),
                if (outOfStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Out of stock',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!outOfStock)
                      QuantityStepper(
                        quantity: item.quantity,
                        min: 1,
                        max: stock,
                        enabled: !pending,
                        onChanged: onQuantityChanged,
                      )
                    else
                      TextButton(
                        onPressed: onTap,
                        child: const Text('Find something similar'),
                      ),
                    const Spacer(),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatPrice(item.subtotal),
                          maxLines: 1,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: pending ? null : onRemove,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!pending) return body;
    return Opacity(
      opacity: 0.55,
      child: IgnorePointer(child: body),
    );
  }
}

class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(72, 72),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(120, 12),
                const SizedBox(height: 8),
                bar(180, 14),
                const SizedBox(height: 8),
                bar(90, 12),
                const SizedBox(height: 12),
                bar(140, 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}