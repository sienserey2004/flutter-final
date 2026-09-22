enum ProductSort {
  newest('newest', 'Newest'),
  priceAsc('price_asc', 'Price: Low to High'),
  priceDesc('price_desc', 'Price: High to Low'),
  rating('rating', 'Top Rated'),
  name('name', 'Name A–Z');

  const ProductSort(this.queryValue, this.label);
  final String queryValue;
  final String label;

  static ProductSort fromQueryValue(String? v) {
    for (final s in ProductSort.values) {
      if (s.queryValue == v) return s;
    }
    return ProductSort.newest;
  }
}

class ProductFilter {
  final int? categoryId;
  final String? type;
  final int? step;
  final List<int> brandIds;
  final List<int> skinTypeIds;
  final List<int> concernIds;
  final List<int> ingredientIds;
  final List<String> claimKeys;
  final double? minPrice;
  final double? maxPrice;
  final bool spfOnly;
  final bool inStockOnly;
  final bool onSaleOnly;
  final String? q;
  final ProductSort sort;

  const ProductFilter({
    this.categoryId,
    this.type,
    this.step,
    this.brandIds = const [],
    this.skinTypeIds = const [],
    this.concernIds = const [],
    this.ingredientIds = const [],
    this.claimKeys = const [],
    this.minPrice,
    this.maxPrice,
    this.spfOnly = false,
    this.inStockOnly = false,
    this.onSaleOnly = false,
    this.q,
    this.sort = ProductSort.newest,
  });

  ProductFilter copyWith({
    Object? categoryId = _sentinel,
    Object? type = _sentinel,
    Object? step = _sentinel,
    List<int>? brandIds,
    List<int>? skinTypeIds,
    List<int>? concernIds,
    List<int>? ingredientIds,
    List<String>? claimKeys,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    bool? spfOnly,
    bool? inStockOnly,
    bool? onSaleOnly,
    Object? q = _sentinel,
    ProductSort? sort,
  }) {
    return ProductFilter(
      categoryId: identical(categoryId, _sentinel) ? this.categoryId : categoryId as int?,
      type: identical(type, _sentinel) ? this.type : type as String?,
      step: identical(step, _sentinel) ? this.step : step as int?,
      brandIds: brandIds ?? this.brandIds,
      skinTypeIds: skinTypeIds ?? this.skinTypeIds,
      concernIds: concernIds ?? this.concernIds,
      ingredientIds: ingredientIds ?? this.ingredientIds,
      claimKeys: claimKeys ?? this.claimKeys,
      minPrice: identical(minPrice, _sentinel) ? this.minPrice : minPrice as double?,
      maxPrice: identical(maxPrice, _sentinel) ? this.maxPrice : maxPrice as double?,
      spfOnly: spfOnly ?? this.spfOnly,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      q: identical(q, _sentinel) ? this.q : q as String?,
      sort: sort ?? this.sort,
    );
  }

  /// Number of *groups* that are active — matches the Filter badge.
  int get activeCount {
    var n = 0;
    if (categoryId != null) n++;
    if (type != null && type!.isNotEmpty) n++;
    if (step != null) n++;
    if (brandIds.isNotEmpty) n++;
    if (skinTypeIds.isNotEmpty) n++;
    if (concernIds.isNotEmpty) n++;
    if (ingredientIds.isNotEmpty) n++;
    if (claimKeys.isNotEmpty) n++;
    if (minPrice != null || maxPrice != null) n++;
    if (spfOnly) n++;
    if (inStockOnly) n++;
    if (onSaleOnly) n++;
    return n;
  }

  bool get isEmpty => activeCount == 0 && (q == null || q!.isEmpty);

  /// Repeated params are emitted as `k=v&k=v2` by hand because a Map loses dupes.
  String toQueryString() {
    final parts = <String>[];
    void add(String k, String v) => parts.add('$k=${Uri.encodeQueryComponent(v)}');

    if (q != null && q!.isNotEmpty) add('q', q!);
    if (categoryId != null) add('category', '$categoryId');
    if (type != null && type!.isNotEmpty) add('type', type!);
    if (step != null) add('step', '$step');
    for (final id in brandIds) {
      add('brand', '$id');
    }
    for (final id in skinTypeIds) {
      add('skin_type', '$id');
    }
    for (final id in concernIds) {
      add('concern', '$id');
    }
    for (final id in ingredientIds) {
      add('ingredient', '$id');
    }
    for (final k in claimKeys) {
      add('claim', k);
    }
    if (minPrice != null) add('min_price', minPrice!.toStringAsFixed(2));
    if (maxPrice != null) add('max_price', maxPrice!.toStringAsFixed(2));
    if (spfOnly) add('spf', '1');
    if (inStockOnly) add('in_stock', '1');
    if (onSaleOnly) add('on_sale', '1');
    if (sort != ProductSort.newest) add('sort', sort.queryValue);
    return parts.join('&');
  }

  static const Object _sentinel = Object();
}