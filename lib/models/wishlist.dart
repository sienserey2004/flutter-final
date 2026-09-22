import 'product.dart';

class WishlistItem {
  final int wishlistItemId;
  final int productId;
  final Product product;
  final DateTime? addedAt;

  const WishlistItem({
    required this.wishlistItemId,
    required this.productId,
    required this.product,
    this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final rawDate = json['added_at'];
    return WishlistItem(
      wishlistItemId: json['wishlist_item_id'] as int? ?? 0,
      productId: json['product_id'] as int,
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      addedAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }
}

class Wishlist {
  final int wishlistId;
  final List<WishlistItem> items;
  final int itemCount;

  const Wishlist({
    required this.wishlistId,
    required this.items,
    required this.itemCount,
  });

  static const Wishlist empty = Wishlist(wishlistId: 0, items: [], itemCount: 0);

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];
    final items = raw
        .map((e) => WishlistItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) {
        final ad = a.addedAt;
        final bd = b.addedAt;
        if (ad != null && bd != null) return bd.compareTo(ad);
        return b.productId.compareTo(a.productId);
      });
    return Wishlist(
      wishlistId: json['wishlist_id'] as int? ?? 0,
      items: items,
      itemCount: json['item_count'] as int? ?? items.length,
    );
  }
}