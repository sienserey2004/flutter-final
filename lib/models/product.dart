/// Card-shaped product, exactly as `Product.to_dict(include_variants: false)`
/// returns it (backend/app/models.py:484).
class KeyIngredient {
  final int? ingredientId;
  final String name;
  final String? inciName;
  final String? concentration;
  final bool isKey;

  const KeyIngredient({
    this.ingredientId,
    required this.name,
    this.inciName,
    this.concentration,
    this.isKey = false,
  });

  factory KeyIngredient.fromJson(Map<String, dynamic> json) {
    return KeyIngredient(
      ingredientId: json['ingredient_id'] as int?,
      name: (json['name'] as String?) ?? '',
      inciName: json['inci_name'] as String?,
      concentration: json['concentration']?.toString(),
      isKey: (json['is_key'] as bool?) ?? false,
    );
  }

  String get displayName =>
      concentration == null || concentration!.isEmpty
          ? name
          : '$name · $concentration';
}

class Product {
  final int productId;
  final int? categoryId;
  final String? category;
  final int? brandId;
  final String? brand;
  final String name;
  final String? slug;
  final String? description;
  final double basePrice;
  final String? productType;
  final int? routineStep;
  final String? routineStepLabel;
  final String? texture;
  final int? spf;
  final int? paoMonths;
  final String? volumeLabel;
  final List<String> claims;
  final List<String> skinTypes;
  final List<String> concerns;
  final List<KeyIngredient> keyIngredients;
  final String? image;
  final List<String> images;
  final double avgRating;
  final int reviewCount;
  final int totalStock;
  final bool isActive;
  final String? createdAt;

  /// Optional — present on some payloads that include variant pricing.
  final double? compareAtPrice;
  final int? discountPercent;
  final bool? isOnSale;

  const Product({
    required this.productId,
    this.categoryId,
    this.category,
    this.brandId,
    this.brand,
    required this.name,
    this.slug,
    this.description,
    required this.basePrice,
    this.productType,
    this.routineStep,
    this.routineStepLabel,
    this.texture,
    this.spf,
    this.paoMonths,
    this.volumeLabel,
    this.claims = const [],
    this.skinTypes = const [],
    this.concerns = const [],
    this.keyIngredients = const [],
    this.image,
    this.images = const [],
    this.avgRating = 0,
    this.reviewCount = 0,
    this.totalStock = 0,
    this.isActive = true,
    this.createdAt,
    this.compareAtPrice,
    this.discountPercent,
    this.isOnSale,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: (json['product_id'] as int?) ?? (json['id'] as int?) ?? 0,
      categoryId: json['category_id'] as int?,
      category: json['category'] as String?,
      brandId: json['brand_id'] as int?,
      brand: json['brand'] as String?,
      name: (json['name'] as String?) ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      basePrice: _toDouble(json['base_price']) ?? 0,
      productType: json['product_type'] as String?,
      routineStep: json['routine_step'] as int?,
      routineStepLabel: json['routine_step_label'] as String?,
      texture: json['texture'] as String?,
      spf: json['spf'] as int?,
      paoMonths: json['pao_months'] as int?,
      volumeLabel: json['volume_label'] as String?,
      claims: _stringList(json['claims']),
      skinTypes: _stringList(json['skin_types']),
      concerns: _stringList(json['concerns']),
      keyIngredients: _ingredientList(json['key_ingredients']),
      image: json['image'] as String?,
      images: _stringList(json['images']),
      avgRating: _toDouble(json['avg_rating']) ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      totalStock: json['total_stock'] as int? ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] as String?,
      compareAtPrice: _toDouble(json['compare_at_price']),
      discountPercent: json['discount_percent'] as int?,
      isOnSale: json['is_on_sale'] as bool?,
    );
  }

  bool get isOutOfStock => totalStock <= 0;

  String? get primaryImage {
    if (image != null && image!.isNotEmpty) return image;
    if (images.isNotEmpty) return images.first;
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static List<KeyIngredient> _ingredientList(dynamic v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => KeyIngredient.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}