import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/product.dart';

void main() {
  test('Product.fromJson null-fallbacks every optional', () {
    final p = Product.fromJson({
      'product_id': 7,
      'name': 'Gentle Cleanser',
      'base_price': '12.50',
      'claims': ['vegan'],
      'skin_types': ['Oily'],
      'concerns': ['Acne'],
      'avg_rating': 4.6,
      'review_count': 28,
      'total_stock': 0,
      'is_active': true,
    });
    expect(p.productId, 7);
    expect(p.basePrice, 12.50);
    expect(p.claims, ['vegan']);
    expect(p.isOutOfStock, isTrue);
    expect(p.texture, isNull);
    expect(p.spf, isNull);
  });
}