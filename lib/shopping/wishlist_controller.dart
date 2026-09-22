import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';
import '../models/wishlist.dart';
import 'wishlist_repository.dart';

enum WishlistStatus { idle, loading, error, ready }

class WishlistController extends ChangeNotifier {
  WishlistController({required ApiClient api}) : _repo = WishlistRepository(api);

  final WishlistRepository _repo;
  Wishlist _wishlist = Wishlist.empty;
  WishlistStatus _status = WishlistStatus.idle;
  String? _errorMessage;
  final Set<int> _savedIds = <int>{};
  final Set<int> _pendingIds = <int>{};
  bool _disposed = false;

  static const _idsKey = 'wishlist_ids_v1';

  Wishlist get wishlist => _wishlist;
  WishlistStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<WishlistItem> get items => _wishlist.items;
  int get count => _savedIds.isNotEmpty ? _savedIds.length : _wishlist.itemCount;
  bool get isBusy => _pendingIds.isNotEmpty;
  Set<int> get pendingIds => Set.unmodifiable(_pendingIds);

  bool isSaved(int productId) => _savedIds.contains(productId);

  void seed(int productId, bool saved) {
    if (saved) {
      _savedIds.add(productId);
    } else {
      _savedIds.remove(productId);
    }
    _safeNotify();
  }

  Future<void> bootstrap() async {
    await _hydrate();
    await fetch();
  }

  Future<void> fetch() async {
    if (_wishlist.items.isEmpty) {
      _status = WishlistStatus.loading;
      _safeNotify();
    }
    try {
      final w = await _repo.fetch();
      _wishlist = w;
      _savedIds
        ..clear()
        ..addAll(w.items.map((i) => i.productId));
      _status = WishlistStatus.ready;
      _errorMessage = null;
      await _persist();
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = _wishlist.items.isEmpty ? WishlistStatus.error : WishlistStatus.ready;
    } catch (e) {
      _errorMessage = e.toString();
      _status = _wishlist.items.isEmpty ? WishlistStatus.error : WishlistStatus.ready;
    }
    _safeNotify();
  }

  /// Returns the resulting `in_wishlist` state.
  Future<bool> toggle(int productId) async {
    final wasSaved = _savedIds.contains(productId);
    // Optimistic flip.
    if (wasSaved) {
      _savedIds.remove(productId);
      _wishlist = _wishlist.copyWith(
        items: _wishlist.items.where((i) => i.productId != productId).toList(),
        itemCount: (_wishlist.itemCount - 1).clamp(0, 1 << 31),
      );
    } else {
      _savedIds.add(productId);
    }
    _pendingIds.add(productId);
    _safeNotify();

    try {
      final res = await _repo.toggle(productId);
      if (res.inWishlist) {
        _savedIds.add(productId);
      } else {
        _savedIds.remove(productId);
        _wishlist = _wishlist.copyWith(
          items: _wishlist.items.where((i) => i.productId != productId).toList(),
          itemCount: res.count,
        );
      }
      await _persist();
      return res.inWishlist;
    } on AuthException catch (e) {
      _rollback(productId, wasSaved);
      _errorMessage = e.message;
      return wasSaved;
    } catch (e) {
      _rollback(productId, wasSaved);
      _errorMessage = e.toString();
      return wasSaved;
    } finally {
      _pendingIds.remove(productId);
      _safeNotify();
    }
  }

  Future<bool> unsave(int productId) async {
    if (!_savedIds.contains(productId)) return true;
    final result = await toggle(productId);
    return !result;
  }

  void _rollback(int productId, bool wasSaved) {
    if (wasSaved) {
      _savedIds.add(productId);
    } else {
      _savedIds.remove(productId);
    }
  }

  void reset() {
    _savedIds.clear();
    _wishlist = Wishlist.empty;
    _status = WishlistStatus.idle;
    _errorMessage = null;
    _pendingIds.clear();
    SharedPreferences.getInstance().then((p) => p.remove(_idsKey));
    _safeNotify();
  }

  Future<void> _hydrate() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_idsKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).cast<num>().map((n) => n.toInt());
      _savedIds.addAll(list);
    } catch (_) {/* best-effort */}
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_idsKey, jsonEncode(_savedIds.toList()));
    } catch (_) {/* best-effort */}
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

extension on Wishlist {
  Wishlist copyWith({List<WishlistItem>? items, int? itemCount}) => Wishlist(
        wishlistId: wishlistId,
        items: items ?? this.items,
        itemCount: itemCount ?? this.itemCount,
      );
}