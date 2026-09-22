import '../auth/auth_controller.dart';
import '../models/wishlist.dart';

class WishlistToggle {
  final bool inWishlist;
  final int count;
  const WishlistToggle(this.inWishlist, this.count);
}

class WishlistRepository {
  WishlistRepository(this._api);
  final ApiClient _api;

  Future<Wishlist> fetch() async {
    final res = await _api.request('/account/wishlist'); // NO trailing slash
    return Wishlist.fromJson(_data(res));
  }

  Future<WishlistToggle> toggle(int productId) async {
    final res = await _api.request(
      '/account/wishlist/toggle',
      method: 'POST',
      body: {'product_id': productId},
    );
    final data = _data(res);
    return WishlistToggle(
      data['in_wishlist'] as bool? ?? false,
      data['wishlist_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return const {};
  }
}