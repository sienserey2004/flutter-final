import '../auth/auth_controller.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import 'product_repository.dart';

class Promo {
  final String? title;
  final String? description;
  final String? startsAt;
  final String? endsAt;
  final String? cta;
  const Promo({this.title, this.description, this.startsAt, this.endsAt, this.cta});

  factory Promo.fromJson(Map<String, dynamic> json) => Promo(
        title: json['title'] as String?,
        description: json['description'] as String?,
        startsAt: json['starts_at'] as String?,
        endsAt: json['ends_at'] as String?,
        cta: json['cta'] as String?,
      );
}

class HomeConcern {
  final int id;
  final String name;
  const HomeConcern({required this.id, required this.name});

  factory HomeConcern.fromJson(Map<String, dynamic> json) => HomeConcern(
        id: (json['id'] as int?) ?? (json['concern_id'] as int?) ?? 0,
        name: (json['name'] as String?) ?? '',
      );
}

class HomePayload {
  final List<Product> newIn;
  final List<Product> bestsellers;
  final List<Product> onSale;
  final List<ProductCategory> categories;
  final List<HomeConcern> concerns;
  final List<Promo> activePromos;
  final int productCount;

  const HomePayload({
    this.newIn = const [],
    this.bestsellers = const [],
    this.onSale = const [],
    this.categories = const [],
    this.concerns = const [],
    this.activePromos = const [],
    this.productCount = 0,
  });
}

class HomeRepository {
  final ApiClient api;
  HomeRepository(this.api);

  Future<HomePayload> fetchHome() async {
    final envelope = await api.request('/');
    final raw = envelope['data'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    return HomePayload(
      newIn: _products(data['new_in']),
      bestsellers: _products(data['bestsellers']),
      onSale: _products(data['on_sale']),
      categories: _categories(data['categories'] ?? data['shelf_categories']),
      concerns: _concerns(data['concerns']),
      activePromos: _promos(data['active_promos']),
      productCount: (data['stats'] is Map)
          ? ((data['stats'] as Map)['products'] as int? ?? 0)
          : 0,
    );
  }

  static List<Product> _products(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static List<ProductCategory> _categories(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static List<HomeConcern> _concerns(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => HomeConcern.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static List<Promo> _promos(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Promo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}