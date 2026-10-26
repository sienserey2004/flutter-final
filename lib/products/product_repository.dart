import '../auth/auth_controller.dart';
import '../models/filter_options.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_detail.dart';
import '../models/product_filter.dart';

class ProductListResult {
  final List<Product> products;
  final int page;
  final int pages;
  final int total;
  final FilterOptions options;

  const ProductListResult({
    required this.products,
    required this.page,
    required this.pages,
    required this.total,
    required this.options,
  });
}

class CategoryProductsResult {
  final ProductCategory? category;
  final List<CategoryBreadcrumb> breadcrumb;
  final List<Product> products;
  final int page;
  final int pages;
  final int total;

  const CategoryProductsResult({
    this.category,
    this.breadcrumb = const [],
    this.products = const [],
    this.page = 1,
    this.pages = 1,
    this.total = 0,
  });
}

class WishlistToggleResult {
  final bool inWishlist;
  final int wishlistCount;
  const WishlistToggleResult({required this.inWishlist, required this.wishlistCount});
}

class RecommendedResult {
  final List<Product> products;
  final Map<String, dynamic>? profile;
  final List<RecommendedRoutineStep> routine;
  final String? message;

  const RecommendedResult({
    this.products = const [],
    this.profile,
    this.routine = const [],
    this.message,
  });
}

class RecommendedRoutineStep {
  final int step;
  final String label;
  final List<Product> products;
  const RecommendedRoutineStep({
    required this.step,
    required this.label,
    this.products = const [],
  });
}

class ProductRepository {
  final ApiClient api;
  ProductRepository(this.api);

  Future<Map<String, dynamic>> _unwrapGet(String path) async {
    final envelope = await api.request(path);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<ProductListResult> fetchProducts(
    ProductFilter filter, {
    int page = 1,
  }) async {
    final qs = filter.toQueryString();
    final path = qs.isEmpty
        ? '/products/?page=$page'
        : '/products/?$qs&page=$page';
    final data = await _unwrapGet(path);
    return ProductListResult(
      products: _products(data['products']),
      page: data['page'] as int? ?? 1,
      pages: data['pages'] as int? ?? 1,
      total: data['total'] as int? ?? 0,
      options: FilterOptions.fromJson(
        data['options'] is Map
            ? Map<String, dynamic>.from(data['options'] as Map)
            : null,
      ),
    );
  }

  Future<List<ProductCategory>> fetchCategoryTree({bool flat = false}) async {
    final data = await _unwrapGet(flat ? '/categories/?flat=1' : '/categories/');
    final raw = data['categories'] ?? data['items'] ?? data;
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<CategoryProductsResult> fetchCategory(
    int categoryId, {
    int page = 1,
  }) async {
    final data = await _unwrapGet('/categories/$categoryId?page=$page');
    final categoryJson = data['category'];
    return CategoryProductsResult(
      category: categoryJson is Map
          ? ProductCategory.fromJson(Map<String, dynamic>.from(categoryJson))
          : null,
      breadcrumb: (data['breadcrumb'] is List)
          ? (data['breadcrumb'] as List)
              .whereType<Map>()
              .map((e) => CategoryBreadcrumb.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      products: _products(data['products']),
      page: data['page'] as int? ?? 1,
      pages: data['pages'] as int? ?? 1,
      total: data['total'] as int? ?? 0,
    );
  }

  Future<ProductDetail> fetchProductDetail(int productId) async {
    final data = await _unwrapGet('/products/$productId');
    return ProductDetail.fromJson(data);
  }

  Future<RecommendedResult> fetchForYou() async {
    final data = await _unwrapGet('/products/for-you');
    final routine = <RecommendedRoutineStep>[];
    final raw = data['routine'];
    if (raw is List) {
      for (final r in raw) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          routine.add(RecommendedRoutineStep(
            step: m['step'] as int? ?? 0,
            label: (m['label'] as String?) ?? '',
            products: _products(m['products']),
          ));
        }
      }
    }
    return RecommendedResult(
      products: _products(data['products']),
      profile: data['profile'] is Map
          ? Map<String, dynamic>.from(data['profile'] as Map)
          : null,
      routine: routine,
      message: data['message'] as String?,
    );
  }

  /// Creates the user's review, or updates it if they already reviewed
  /// this product (the backend keeps one review per user per product).
  Future<ProductReview> submitReview({
    required int productId,
    required int rating,
    String title = '',
    String comment = '',
  }) async {
    final envelope = await api.request(
      '/reviews/submit',
      method: 'POST',
      body: {
        'product_id': productId,
        'rating': rating,
        'title': title.trim(),
        'comment': comment.trim(),
      },
    );
    return ProductReview.fromJson(Map<String, dynamic>.from(envelope['data'] as Map));
  }

  Future<WishlistToggleResult> toggleWishlist(int productId) async {
    final envelope = await api.request(
      '/account/wishlist/toggle',
      method: 'POST',
      body: {'product_id': productId},
    );
    final data = envelope['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    return WishlistToggleResult(
      inWishlist: (map['in_wishlist'] as bool?) ?? false,
      wishlistCount: map['wishlist_count'] as int? ?? 0,
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
}