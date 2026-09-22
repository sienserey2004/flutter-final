import 'package:flutter/material.dart';

import '../screens/shopping/cart_screen.dart';
import '../shopping/cart_scope.dart';

class CartButton extends StatelessWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final count = cart.badgeCount;
    return Semantics(
      button: true,
      label: count > 0 ? 'Cart, $count items' : 'Cart, empty',
      child: IconButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_bag_outlined),
            Positioned(
              right: -6,
              top: -6,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: count <= 0
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(count),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}