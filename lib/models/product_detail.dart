import 'product.dart';

class ProductVariant {
  final int? variantId;
  final double price;
  final double? compareAtPrice;
  final bool isOnSale;
  final int? discountPercent;
  final int stock;
  final String label;
  final String? image;

  const ProductVariant({
    this.variantId,
    required this.price,
    this.compareAtPrice,
    this.isOnSale = false,
    this.discountPercent,
    this.stock = 0,
    required this.label,
    this.image,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: json['variant_id'] as int?,
      price: _toDouble(json['price']) ?? 0,
      compareAtPrice: _toDouble(json['compare_at_price']),
      isOnSale: (json['is_on_sale'] as bool?) ?? false,
      discountPercent: json['discount_percent'] as int?,
      stock: json['stock'] as int? ?? 0,
      label: (json['label'] as String?) ?? '',
      image: json['image'] as String?,
    );
  }

  bool get isOutOfStock => stock <= 0;

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class ProductReview {
  final int? reviewId;
  final String userName;
  final double rating;
  final String? skinType;
  final String? title;
  final String? comment;
  final String? createdAt;

  const ProductReview({
    this.reviewId,
    required this.userName,
    required this.rating,
    this.skinType,
    this.title,
    this.comment,
    this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      reviewId: json['review_id'] as int?,
      userName: (json['user_name'] as String?) ?? 'Anonymous',
      rating: _toDouble(json['rating']) ?? 0,
      skinType: json['skin_type'] as String?,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class ProductDetail {
  final Product product;
  final List<ProductVariant> variants;
  final String? howToUse;
  final String? ingredientsFull;
  final List<KeyIngredient> ingredients;
  final List<ProductReview> reviews;
  final Map<int, int> ratingBreakdown;
  final List<Product> related;
  final List<Product> routine;
  final bool inWishlist;

  const ProductDetail({
    required this.product,
    this.variants = const [],
    this.howToUse,
    this.ingredientsFull,
    this.ingredients = const [],
    this.reviews = const [],
    this.ratingBreakdown = const {},
    this.related = const [],
    this.routine = const [],
    this.inWishlist = false,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    final product = productJson is Map
        ? Product.fromJson(Map<String, dynamic>.from(productJson))
        : Product.fromJson(const {});

    final breakdown = <int, int>{};
    final raw = json['rating_breakdown'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final star = int.tryParse(k.toString());
        final count = v is int ? v : int.tryParse(v.toString());
        if (star != null && count != null) breakdown[star] = count;
      });
    }

    return ProductDetail(
      product: product,
      variants: _listOf(json['product'], 'variants', ProductVariant.fromJson),
      howToUse: _stringOf(json['product'], 'how_to_use') ?? (json['how_to_use'] as String?),
      ingredientsFull:
          _stringOf(json['product'], 'ingredients_full') ?? (json['ingredients_full'] as String?),
      ingredients: _ingredients(json['product']),
      reviews: _list(json['reviews'], ProductReview.fromJson),
      ratingBreakdown: breakdown,
      related: _list(json['related'], Product.fromJson),
      routine: _list(json['routine'], Product.fromJson),
      inWishlist: (json['in_wishlist'] as bool?) ?? false,
    );
  }

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => f(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static List<T> _listOf<T>(
    dynamic parent,
    String key,
    T Function(Map<String, dynamic>) f,
  ) {
    if (parent is Map) return _list(parent[key], f);
    return const [];
  }

  static String? _stringOf(dynamic parent, String key) {
    if (parent is Map) return parent[key] as String?;
    return null;
  }

  static List<KeyIngredient> _ingredients(dynamic parent) {
    if (parent is Map) {
      final raw = parent['key_ingredients'] ?? parent['ingredients'];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => KeyIngredient.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return const [];
  }
}
