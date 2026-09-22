class NamedOption {
  final int id;
  final String label;
  final int? count;

  const NamedOption({required this.id, required this.label, this.count});

  factory NamedOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as int?) ?? (json['value'] as int?) ?? 0;
    final label =
        (json['name'] as String?) ?? (json['label'] as String?) ?? '';
    return NamedOption(id: id, label: label, count: json['count'] as int?);
  }
}

class ClaimOption {
  final String key;
  final String label;

  const ClaimOption({required this.key, required this.label});

  factory ClaimOption.fromJson(String key, dynamic value) {
    final label = value is String
        ? value
        : (value is Map ? (value['label'] as String? ?? key) : key);
    return ClaimOption(key: key, label: label);
  }
}

class FilterOptions {
  final List<NamedOption> brands;
  final List<NamedOption> skinTypes;
  final List<NamedOption> concerns;
  final List<NamedOption> ingredients;
  final List<String> productTypes;
  final List<NamedOption> routineSteps;
  final List<ClaimOption> claims;
  final Map<String, String> sorts;
  final double? minPrice;
  final double? maxPrice;

  const FilterOptions({
    this.brands = const [],
    this.skinTypes = const [],
    this.concerns = const [],
    this.ingredients = const [],
    this.productTypes = const [],
    this.routineSteps = const [],
    this.claims = const [],
    this.sorts = const {},
    this.minPrice,
    this.maxPrice,
  });

  static const FilterOptions empty = FilterOptions(
    sorts: {
      'newest': 'Newest',
      'price_asc': 'Price: Low to High',
      'price_desc': 'Price: High to Low',
      'rating': 'Top Rated',
      'name': 'Name A–Z',
    },
  );

  factory FilterOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    final brands = _named(json['brands']);
    final skinTypes = _named(json['skin_types']);
    final concerns = _named(json['concerns']);
    final ingredients = _named(json['ingredients']);
    final types = _strings(json['product_types']);
    final steps = _named(json['routine_steps']);
    final claims = <ClaimOption>[];
    final rawClaims = json['claims'];
    if (rawClaims is Map) {
      rawClaims.forEach((k, v) => claims.add(ClaimOption.fromJson(k.toString(), v)));
    } else if (rawClaims is List) {
      for (final c in rawClaims) {
        if (c is Map) {
          final key = (c['key'] ?? c['value'])?.toString() ?? '';
          final label = (c['label'] ?? c['name'] ?? key).toString();
          if (key.isNotEmpty) claims.add(ClaimOption(key: key, label: label));
        }
      }
    }

    final sorts = <String, String>{};
    final rawSorts = json['sorts'];
    if (rawSorts is Map) {
      rawSorts.forEach((k, v) => sorts[k.toString()] = v.toString());
    } else if (rawSorts is List) {
      for (final s in rawSorts) {
        if (s is Map) {
          final key = (s['value'] ?? s['key'])?.toString() ?? '';
          final label = (s['label'] ?? s['name'] ?? key).toString();
          if (key.isNotEmpty) sorts[key] = label;
        }
      }
    }

    final price = json['price_range'];
    double? minP, maxP;
    if (price is Map) {
      minP = _toDouble(price['min']);
      maxP = _toDouble(price['max']);
    }

    return FilterOptions(
      brands: brands,
      skinTypes: skinTypes,
      concerns: concerns,
      ingredients: ingredients,
      productTypes: types,
      routineSteps: steps,
      claims: claims,
      sorts: sorts.isEmpty ? empty.sorts : sorts,
      minPrice: minP,
      maxPrice: maxP,
    );
  }

  static List<NamedOption> _named(dynamic v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => NamedOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static List<String> _strings(dynamic v) {
    if (v is List) {
      return v
          .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['value'] ?? e['name'] ?? '').toString();
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}