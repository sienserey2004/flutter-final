import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../shopping/cart_controller.dart';
import '../../shopping/cart_scope.dart';
import '../../widgets/app_button.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/cart_summary_card.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/state_views.dart';
import '../orders/checkout_screen.dart';
import '../products/product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.onCheckout});

  final VoidCallback? onCheckout;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartController? _cart;
  bool _kickedOff = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cart ??= CartScope.of(context, listen: false);
    if (!_kickedOff) {
      _kickedOff = true;
      // Only fetch if we don't already have data; the button/Profile row
      // has usually bootstrapped us already.
      if (_cart!.status == CartStatus.idle) {
        _cart!.bootstrap();
      }
    }
  }

  Future<void> _refresh() => _cart!.refresh();

  Future<void> _confirmClear() async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Clear your cart?',
      message: 'All items will be removed.',
      confirmLabel: 'Clear cart',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _cart!.clear();
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Cart cleared')));
  }

  Future<void> _remove(CartItem item) async {
    if (item.quantity > 1) {
      final ok = await ConfirmationDialog.show(
        context,
        title: 'Remove item?',
        message: 'Remove "${item.productName}" from your cart?',
        confirmLabel: 'Remove',
        destructive: true,
      );
      if (ok != true || !mounted) return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final qty = item.quantity;
    final variantId = item.variantId;
    final ok = await _cart!.remove(item.cartItemId);
    if (!mounted) return;
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(_cart!.errorMessage ?? 'Could not remove item')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${item.productName}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _cart!.add(variantId: variantId, quantity: qty),
        ),
      ),
    );
  }

  void _setQty(CartItem item, int qty) {
    if (qty < 1) {
      _remove(item);
      return;
    }
    _cart!.setQuantity(item.cartItemId, qty);
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final theme = Theme.of(context);

    final showFirstLoad = cart.status == CartStatus.loading && cart.isEmpty;
    final showHardError = cart.status == CartStatus.error && cart.isEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('My Cart'),
            const SizedBox(width: 8),
            if (!cart.isEmpty)
              Text(
                '${cart.itemCount} ${cart.itemCount == 1 ? "item" : "items"}',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
      body: _body(cart, showFirstLoad, showHardError),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: cart.isBusy ? null : _confirmClear,
                      child: const Text('Clear cart'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Proceed to Checkout',
                        isLoading: cart.isBusy,
                        onPressed: cart.isEmpty || cart.isBusy
                            ? null
                            : () {
                                if (widget.onCheckout != null) {
                                  widget.onCheckout!();
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(
                                        items: List.of(cart.cart.items),
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _body(CartController cart, bool firstLoad, bool hardError) {
    if (firstLoad) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          CartItemSkeleton(),
          CartItemSkeleton(),
          CartItemSkeleton(),
        ],
      );
    }
    if (hardError) {
      return ErrorStateView(
        message: 'Could not load cart.',
        onRetry: _refresh,
      );
    }
    if (cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        message: 'Add a product and it will wait for you here.',
        action: AppButton(
          label: 'Browse products',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }
    return Column(
      children: [
        if (cart.errorMessage != null)
          ErrorBanner(message: cart.errorMessage!),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cart.cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.cart.items[i];
                return Dismissible(
                  key: ValueKey(item.cartItemId),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => ConfirmationDialog.show(
                    context,
                    title: 'Remove item?',
                    message: 'Remove "${item.productName}"?',
                    confirmLabel: 'Remove',
                    destructive: true,
                  ),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onDismissed: (_) {
                    final messenger = ScaffoldMessenger.of(context);
                    final qty = item.quantity;
                    final vid = item.variantId;
                    cart.remove(item.cartItemId);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Removed "${item.productName}"'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () =>
                              cart.add(variantId: vid, quantity: qty),
                        ),
                      ),
                    );
                  },
                  child: CartItemTile(
                    item: item,
                    pending: cart.pendingItemIds.contains(item.cartItemId),
                    onQuantityChanged: (q) => _setQty(item, q),
                    onRemove: () => _remove(item),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(productId: item.productId),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        CartSummaryCard(cart: cart.cart),
      ],
    );
  }
}
