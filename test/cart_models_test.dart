import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/cart.dart';
import 'package:app/models/cart_item.dart';
import 'package:app/models/product_detail.dart';

void main() {
  test('empty cart parses int total from server', () {
    final cart = Cart.fromJson({
      'cart_id': 1,
      'items': <Map<String, dynamic>>[],
      'total': 0, // Python int, not double
      'item_count': 0,
    });
    expect(cart.total, 0);
    expect(cart.itemCount, 0);
    expect(cart.isEmpty, isTrue);
  });

  test('items are sorted by cart_item_id ascending', () {
    final cart = Cart.fromJson({
      'cart_id': 1,
      'item_count': 2,
      'total': 100.0,
      'items': [
        {
          'cart_item_id': 9,
          'variant_id': 1,
          'quantity': 1,
          'subtotal': 50.0,
          'variant': <String, dynamic>{
            'variant_id': 1,
            'price': 50.0,
            'stock': 10,
          },
          'product_id': 1,
          'product_name': 'A',
        },
        {
          'cart_item_id': 3,
          'variant_id': 2,
          'quantity': 1,
          'subtotal': 50.0,
          'variant': <String, dynamic>{
            'variant_id': 2,
            'price': 50.0,
            'stock': 10,
          },
          'product_id': 2,
          'product_name': 'B',
        },
      ],
    });
    expect(cart.items.map((i) => i.cartItemId), [3, 9]);
  });

  test('cart item exposes brand_name and pre-rendered product_name', () {
    final item = CartItem.fromJson({
      'cart_item_id': 1,
      'variant_id': 11,
      'quantity': 2,
      'subtotal': 40.0,
      'variant': <String, dynamic>{
        'variant_id': 11,
        'price': 20.0,
        'stock': 5,
      },
      'product_id': 7,
      'product_name': 'Gentle Cleanser',
      'brand_name': 'Acme',
    });
    expect(item.productName, 'Gentle Cleanser');
    expect(item.brandName, 'Acme');
    expect(item.subtotal, 40.0);
  });
}