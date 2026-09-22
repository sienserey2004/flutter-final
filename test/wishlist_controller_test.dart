import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_controller.dart';
import 'package:app/shopping/wishlist_controller.dart';

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

Map<String, dynamic> _product(int id) => {
      'id': id,
      'name': 'P$id',
      'variants': <Map<String, dynamic>>[],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('toggle optimistically flips and settles on server value', () async {
    final api = FakeApi((m, p, b) async {
      if (p == '/account/wishlist/toggle') {
        return {
          'success': true,
          'data': {'in_wishlist': true, 'wishlist_count': 1},
        };
      }
      return {'success': true, 'data': {}};
    });
    final c = WishlistController(api: api);
    expect(c.isSaved(1), isFalse);
    final saved = await c.toggle(1);
    expect(saved, isTrue);
    expect(c.isSaved(1), isTrue);
    c.dispose();
  });

  test('failed toggle rolls back the heart', () async {
    final api = FakeApi((m, p, b) async {
      throw AuthException('boom');
    });
    final c = WishlistController(api: api);
    final before = c.isSaved(7);
    await c.toggle(7);
    expect(c.isSaved(7), before);
    c.dispose();
  });

  test('fetch hydrates savedIds from the server payload', () async {
    final api = FakeApi((m, p, b) async {
      if (p == '/account/wishlist') {
        return {
          'success': true,
          'data': {
            'wishlist_id': 1,
            'item_count': 2,
            'items': [
              {
                'wishlist_item_id': 10,
                'product_id': 1,
                'product': _product(1),
                'added_at': '2024-01-01T00:00:00',
              },
              {
                'wishlist_item_id': 11,
                'product_id': 2,
                'product': _product(2),
                'added_at': '2024-02-01T00:00:00',
              },
            ],
          },
        };
      }
      return {'success': true, 'data': {}};
    });
    final c = WishlistController(api: api);
    await c.fetch();
    expect(c.isSaved(1), isTrue);
    expect(c.isSaved(2), isTrue);
    // newest added_at first
    expect(c.items.first.productId, 2);
    c.dispose();
  });
}