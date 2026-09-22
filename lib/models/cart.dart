import 'cart_item.dart';

class Cart {
  final int cartId;
  final List<CartItem> items;
  final double total;
  final int itemCount;

  const Cart({
    required this.cartId,
    required this.items,
    required this.total,
    required this.itemCount,
  });

  static const Cart empty = Cart(cartId: 0, items: [], total: 0, itemCount: 0);

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    final items = raw
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.cartItemId.compareTo(b.cartItemId));
    return Cart(
      cartId: json['cart_id'] as int? ?? 0,
      items: items,
      // Money is never `as double`: server returns int 0 for an empty cart.
      total: (json['total'] as num?)?.toDouble() ?? 0,
      itemCount: json['item_count'] as int? ??
          items.fold<int>(0, (s, i) => s + i.quantity),
    );
  }

  Cart copyWith({List<CartItem>? items, double? total, int? itemCount}) => Cart(
        cartId: cartId,
        items: items ?? this.items,
        total: total ?? this.total,
        itemCount: itemCount ?? this.itemCount,
      );
}