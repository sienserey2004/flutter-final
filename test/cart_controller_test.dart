import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_controller.dart';
import 'package:app/shopping/cart_controller.dart';

/// Minimal `ApiClient` subclass. If your `ApiClient` has required
/// constructor args, pass them in the `super(...)` call.
class FakeApi extends ApiClient {
  FakeApi(this.handler);

  final Future<Map<String, dynamic>> Function(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) handler;

  @override
  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) =>
      handler(method, path, body);
}

Map<String, dynamic> _cart({
  int count = 0,
  double total = 0,
  List<Map<String, dynamic>> items = const [],
  String? warning,
}) =>
    {
      'success': true,
      'data': {
        'cart_id': 1,
        'items': items,
        'total': total,
        'item_count': count,
      },
      if (warning != null) 'warning': warning,
    };

Map<String, dynamic> _item(int id, int variantId, int qty, double price) => {
      'cart_item_id': id,
      'variant_id': variantId,
      'quantity': qty,
      'subtotal': price * qty,
      'variant': {
        'variant_id': variantId,
        'price': price,
        'stock': 10,
      },
      'product_id': id,
      'product_name': 'P$id',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add surfaces server warning and replaces cart', () async {
    final api = FakeApi((m, p, b) async {
      if (p == '/cart/add') {
        return _cart(
          count: 1,
          total: 9.99,
          items: [_item(1, 1, 1, 9.99)],
          warning: 'Only 1 in stock.',
        );
      }
      return _cart();
    });
    final c = CartController(api: api);
    final ok = await c.add(variantId: 1);
    expect(ok, isTrue);
    expect(c.itemCount, 1);
    expect(c.takeWarning(), 'Only 1 in stock.');
    expect(c.takeWarning(), isNull); // one-shot
    c.dispose();
  });

  test('refresh sequence guard drops a stale response', () async {
    final slow = Completer<Map<String, dynamic>>();
    var call = 0;
    final api = FakeApi((m, p, b) async {
      if (p == '/cart/') {
        call++;
        if (call == 1) return slow.future as Future<Map<String, dynamic>>;
        return _cart(count: 2, total: 20, items: [_item(1, 1, 2, 10)]);
      }
      return _cart();
    });
    final c = CartController(api: api);
    final first = c.refresh();
    final second = c.refresh();
    await second;
    // A late first response must not overwrite the newer one.
    slow.complete(_cart(count: 99, total: 999, items: []));
    await first;
    expect(c.itemCount, 2);
    c.dispose();
  });

  test('setQuantity debounces rapid taps into one request', () async {
    var updateCalls = 0;
    final api = FakeApi((m, p, b) async {
      if (p.startsWith('/cart/update/')) {
        updateCalls++;
        return _cart(count: 5, total: 50, items: [_item(1, 1, 5, 10)]);
      }
      if (p == '/cart/') {
        return _cart(count: 1, total: 10, items: [_item(1, 1, 1, 10)]);
      }
      return _cart();
    });
    final c = CartController(api: api);
    await c.refresh();
    c.setQuantity(1, 2);
    c.setQuantity(1, 3);
    c.setQuantity(1, 4);
    c.setQuantity(1, 5);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(updateCalls, 1);
    expect(c.cart.items.first.quantity, 5);
    c.dispose();
  });

  test('failed remove restores the previous cart', () async {
    final api = FakeApi((m, p, b) async {
      if (p == '/cart/') {
        return _cart(count: 1, total: 10, items: [_item(1, 1, 1, 10)]);
      }
      if (p.startsWith('/cart/remove/')) {
        throw AuthException('Not found');
      }
      return _cart();
    });
    final c = CartController(api: api);
    await c.refresh();
    final ok = await c.remove(1);
    expect(ok, isFalse);
    expect(c.itemCount, 1); // rolled back
    c.dispose();
  });
}