import 'product_detail.dart'; // ProductVariant (Plan 2)

class CartItem {
  final int cartItemId;
  final int variantId;
  final int quantity;
  final double subtotal;
  final ProductVariant variant;
  final int productId;
  final String productName;
  final String? brandName;

  const CartItem({
    required this.cartItemId,
    required this.variantId,
    required this.quantity,
    required this.subtotal,
    required this.variant,
    required this.productId,
    required this.productName,
    this.brandName,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'] as int,
      variantId: json['variant_id'] as int,
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      variant: ProductVariant.fromJson(json['variant'] as Map<String, dynamic>),
      productId: json['product_id'] as int,
      productName: json['product_name'] as String? ?? '',
      brandName: json['brand_name'] as String?,
    );
  }

  CartItem copyWith({int? quantity, double? subtotal}) => CartItem(
        cartItemId: cartItemId,
        variantId: variantId,
        quantity: quantity ?? this.quantity,
        subtotal: subtotal ?? this.subtotal,
        variant: variant,
        productId: productId,
        productName: productName,
        brandName: brandName,
      );
}