import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../models/product_detail.dart';
import '../../models/wishlist.dart';
import '../../shopping/cart_scope.dart';
import '../../shopping/wishlist_controller.dart';
import '../../shopping/wishlist_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/products/product_card.dart';
import '../../widgets/state_views.dart';
import '../products/product_detail_screen.dart';
import 'cart_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  WishlistController? _wl;
  bool _kickedOff = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wl ??= WishlistScope.of(context, listen: false);
    if (!_kickedOff) {
      _kickedOff = true;
      if (_wl!.status == WishlistStatus.idle) {
        _wl!.bootstrap();
      }
    }
  }

  Future<void> _refresh() => _wl!.fetch();

  Future<void> _unsave(WishlistItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await _wl!.toggle(item.productId);
    if (!mounted) return;
    if (res) {
      // It got re-saved; don't toast.
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${item.product.name}" from wishlist'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _wl!.toggle(item.productId),
        ),
      ),
    );
  }

  Future<void> _moveToCart(WishlistItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cart = CartScope.of(context, listen: false);
    final api = AuthScope.of(context, listen: false).api;

    try {
      // Wishlist payload has no variants; fetch the detail to pick a default.
      final res = await api.request('/products/${item.productId}');
      final data = res['data'];
      if (data is! Map) throw StateError('Bad product payload');
      final product = ProductDetail.fromJson(Map<String, dynamic>.from(data));
      final variant = _defaultVariant(product);
      if (variant == null) {
        messenger.showSnackBar(
          SnackBar(content: Text('"${item.product.name}" is out of stock')),
        );
        return;
      }
      final variantId = variant.variantId;
      if (variantId == null) return;
      final ok = await cart.add(variantId: variantId);
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(cart.errorMessage ?? 'Could not add to cart')),
        );
        return;
      }
      await _wl!.unsave(item.productId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Moved to cart'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => navigator.push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add to cart: $e')),
      );
    }
  }

  ProductVariant? _defaultVariant(ProductDetail product) {
    final inStock = product.variants.where((v) => v.stock > 0).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    return inStock.isEmpty ? null : inStock.first;
  }

  Future<void> _addAllToCart() async {
    final messenger = ScaffoldMessenger.of(context);
    final items = List<WishlistItem>.from(_wl!.items);
    if (items.isEmpty) return;
    var added = 0;
    var skipped = 0;
    // Sequential on purpose: each add returns a whole-cart snapshot.
    for (final item in items) {
      final before = added;
      try {
        final api = AuthScope.of(context, listen: false).api;
        final res = await api.request('/products/${item.productId}');
        final data = res['data'];
        if (data is! Map) {
          skipped++;
          continue;
        }
        final product = ProductDetail.fromJson(Map<String, dynamic>.from(data));
        final variant = _defaultVariant(product);
        if (variant == null) {
          skipped++;
          continue;
        }
        final variantId = variant.variantId;
        if (variantId == null) {
          skipped++;
          continue;
        }
        final ok = await CartScope.of(context, listen: false)
            .add(variantId: variantId);
        if (ok) {
          added = before + 1;
          await _wl!.unsave(item.productId);
        } else {
          skipped++;
        }
      } catch (_) {
        skipped++;
      }
    }
    if (!mounted) return;
    await _wl!.fetch();
    if (!mounted) return;
    final msg = skipped == 0
        ? 'Added $added ${added == 1 ? "product" : "products"}'
        : 'Added $added ${added == 1 ? "product" : "products"} · $skipped out of stock';
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final wl = WishlistScope.of(context);
    final items = wl.items;
    final theme = Theme.of(context);
    final loading =
        wl.status == WishlistStatus.loading && items.isEmpty;
    final hardError =
        wl.status == WishlistStatus.error && items.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Wishlist'),
            const SizedBox(width: 8),
            if (items.isNotEmpty)
              Text('${wl.count} saved', style: theme.textTheme.bodyMedium),
          ],
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: wl.isBusy ? null : _addAllToCart,
              child: const Text('Add all to cart'),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : hardError
              ? ErrorStateView(
                  message: 'Could not load wishlist.',
                  onRetry: _refresh,
                )
              : items.isEmpty
                  ? EmptyState(
                      icon: Icons.favorite_border,
                      title: 'No favorites yet',
                      message: 'Tap the heart on a product to keep it here.',
                      action: AppButton(
                        label: 'Browse products',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.66,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final it = items[i];
                          final product = it.product;
                          return GestureDetector(
                            onLongPress: () => _sheet(it),
                            child: ProductCard(
                              product: product,
                              isWishlisted: wl.isSaved(it.productId),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    productId: it.productId,
                                  ),
                                ),
                              ),
                              onToggleWishlist: () => _unsave(it),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _sheet(WishlistItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Add to cart'),
              onTap: () {
                Navigator.pop(ctx);
                _moveToCart(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Remove from wishlist'),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await ConfirmationDialog.show(
                  context,
                  title: 'Remove from wishlist?',
                  message: 'Remove "${item.product.name}" from your wishlist?',
                  confirmLabel: 'Remove',
                  destructive: true,
                );
                if (ok == true) _unsave(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}
