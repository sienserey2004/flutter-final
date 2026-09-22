import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/product_filter.dart';

void main() {
  test('repeated query params are emitted in order', () {
    const f = ProductFilter(
      categoryId: 3,
      brandIds: [1, 2],
      concernIds: [4, 7],
      claimKeys: ['vegan', 'fragrance_free'],
      sort: ProductSort.priceAsc,
    );
    expect(
      f.toQueryString(),
      'category=3&brand=1&brand=2&concern=4&concern=7'
      '&claim=vegan&claim=fragrance_free&sort=price_asc',
    );
  });

  test('activeCount counts groups', () {
    const f = ProductFilter(
      categoryId: 1,
      brandIds: [1, 2, 3],
      onSaleOnly: true,
    );
    expect(f.activeCount, 3);
  });

  test('copyWith(null) clears scalar fields', () {
    const f = ProductFilter(categoryId: 5, type: 'Serum');
    final g = f.copyWith(categoryId: null);
    expect(g.categoryId, isNull);
    expect(g.type, 'Serum');
  });
}