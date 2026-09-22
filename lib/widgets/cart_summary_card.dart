import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/cart.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          _row(context, 'Items', '${cart.itemCount}'),
          const SizedBox(height: 8),
          _row(context, 'Subtotal', formatPrice(cart.total)),
          const SizedBox(height: 8),
          _row(context, 'Shipping', 'Calculated at checkout'),
          // PLAN 4: discount row
          const Divider(height: 24),
          Row(
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  formatPrice(cart.total),
                  key: ValueKey(cart.total),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}