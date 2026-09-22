class ProductCategory {
  final int categoryId;
  final int? parentId;
  final String name;
  final String? slug;
  final String? image;
  final int sortOrder;
  final int productCount;
  final int totalProductCount;
  final List<ProductCategory> children;

  const ProductCategory({
    required this.categoryId,
    this.parentId,
    required this.name,
    this.slug,
    this.image,
    this.sortOrder = 0,
    this.productCount = 0,
    this.totalProductCount = 0,
    this.children = const [],
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final kids = json['children'];
    return ProductCategory(
      categoryId: (json['category_id'] as int?) ?? (json['id'] as int?) ?? 0,
      parentId: json['parent_id'] as int?,
      name: (json['name'] as String?) ?? '',
      slug: json['slug'] as String?,
      image: json['image'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      productCount: json['product_count'] as int? ?? 0,
      totalProductCount: json['total_product_count'] as int? ?? 0,
      children: kids is List
          ? kids
              .whereType<Map>()
              .map((e) => ProductCategory.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  bool get hasChildren => children.isNotEmpty;
}

class CategoryBreadcrumb {
  final int categoryId;
  final String name;

  const CategoryBreadcrumb({required this.categoryId, required this.name});

  factory CategoryBreadcrumb.fromJson(Map<String, dynamic> json) => CategoryBreadcrumb(
        categoryId: (json['category_id'] as int?) ?? (json['id'] as int?) ?? 0,
        name: (json['name'] as String?) ?? '',
      );
}