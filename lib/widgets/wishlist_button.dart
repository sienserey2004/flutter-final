import 'package:flutter/material.dart';

import '../screens/shopping/wishlist_screen.dart';
import '../shopping/wishlist_scope.dart';

/// Heart icon that opens the wishlist, with a badge showing how many
/// products are saved. Mirrors [CartButton].
class WishlistButton extends StatelessWidget {
  const WishlistButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = WishlistScope.of(context).count;
    return Semantics(
      button: true,
      label: count > 0 ? 'Wishlist, $count saved' : 'Wishlist, empty',
      child: IconButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WishlistScreen()),
          );
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.favorite_border_rounded),
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
