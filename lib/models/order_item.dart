// lib/models/order_item.dart
import '../core/image_url.dart';
import 'product_detail.dart';

class OrderItem {
  final int orderItemId;
  final int variantId;
  final int quantity;
  final double price;
  final double subtotal;
  final String? productName;
  final String? variantLabel;
  final ProductVariant? variant;

  const OrderItem({
    required this.orderItemId,
    required this.variantId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.productName,
    this.variantLabel,
    this.variant,
  });

  /// Renders the snapshot name first; falls back to the live variant.
  String get displayName =>
      (productName?.isNotEmpty == true ? productName! : null) ??
      'Product';

  String? get displayVariantLabel =>
      (variantLabel?.isNotEmpty == true ? variantLabel : null) ??
      variant?.label;

  String? get imageUrl {
    final path = variant?.image;
    if (path == null || path.isEmpty) return null;
    return resolveImageUrl(path);
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return OrderItem(
      orderItemId: json['order_item_id'] as int,
      variantId: json['variant_id'] as int,
      quantity: (json['quantity'] as num).toInt(),
      price: d('price'),
      subtotal: d('subtotal'),
      productName: json['product_name'] as String?,
      variantLabel: json['variant_label'] as String?,
      variant: json['variant'] == null
          ? null
          : ProductVariant.fromJson(json['variant'] as Map<String, dynamic>),
    );
  }
}
