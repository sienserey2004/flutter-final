import '../auth/auth_controller.dart';
import '../models/cart.dart';

class CartMutation {
  final Cart cart;
  final String? warning;
  const CartMutation(this.cart, {this.warning});
}

class CartRepository {
  CartRepository(this._api);
  final ApiClient _api;

  Future<Cart> fetch() async {
    final res = await _api.request('/cart/'); // trailing slash matters
    return Cart.fromJson(_data(res));
  }

  Future<CartMutation> add({required int variantId, int quantity = 1}) =>
      _post('/cart/add', {'variant_id': variantId, 'quantity': quantity});

  Future<CartMutation> addBundle(int bundleId) =>
      _post('/cart/add-bundle', {'bundle_id': bundleId});

  Future<CartMutation> setQuantity(int cartItemId, int quantity) =>
      _post('/cart/update/$cartItemId', {'quantity': quantity});

  Future<CartMutation> remove(int cartItemId) =>
      _post('/cart/remove/$cartItemId', null);

  Future<CartMutation> clear() => _post('/cart/clear', null);

  Future<CartMutation> _post(String path, Map<String, dynamic>? body) async {
    final res = await _api.request(path, method: 'POST', body: body);
    return CartMutation(
      Cart.fromJson(_data(res)),
      warning: res['warning'] as String?,
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return const {};
  }
}