import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';
import '../models/cart.dart';
import 'cart_repository.dart';

enum CartStatus { idle, loading, error, ready }

class CartController extends ChangeNotifier {
  CartController({required ApiClient api}) : _repo = CartRepository(api);

  final CartRepository _repo;
  Cart _cart = Cart.empty;
  CartStatus _status = CartStatus.idle;
  String? _errorMessage;
  String? _warning;
  int _seq = 0;
  bool _isBusy = false;
  int? _cachedCount;
  double? _cachedTotal;
  final Set<int> _pendingItemIds = <int>{};
  final Map<int, Timer> _debounce = <int, Timer>{};
  bool _disposed = false;

  static const _summaryKey = 'cart_summary_v1';

  Cart get cart => _cart;
  CartStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cart.itemCount;
  double get total => _cart.total;
  bool get isEmpty => _cart.isEmpty;
  Set<int> get pendingItemIds => Set.unmodifiable(_pendingItemIds);
  bool get isBusy => _isBusy;

  /// Badge count that survives cold start: server number if we have one,
  /// otherwise the cached summary (never a fabricated total).
  int get badgeCount {
    if (_status == CartStatus.ready) return _cart.itemCount;
    return _cachedCount ?? 0;
  }

  String? takeWarning() {
    final w = _warning;
    _warning = null;
    return w;
  }

  Future<void> bootstrap() async {
    await _hydrateCache();
    await refresh();
  }

  Future<void> refresh() async {
    final seq = ++_seq;
    if (_cart.isEmpty && _status != CartStatus.ready) {
      _status = CartStatus.loading;
      _safeNotify();
    }
    try {
      final c = await _repo.fetch();
      if (seq != _seq || _disposed) return;
      _cart = c;
      _status = CartStatus.ready;
      _errorMessage = null;
      await _persistSummary();
    } on AuthException catch (e) {
      if (seq != _seq || _disposed) return;
      _errorMessage = e.message;
      _status = _cart.isEmpty ? CartStatus.error : CartStatus.ready;
    } catch (e) {
      if (seq != _seq || _disposed) return;
      _errorMessage = e.toString();
      _status = _cart.isEmpty ? CartStatus.error : CartStatus.ready;
    }
    _safeNotify();
  }

  Future<bool> add({required int variantId, int quantity = 1}) async {
    if (quantity < 1) return false;
    _isBusy = true;
    _safeNotify();
    final snapshot = _cart;
    try {
      final m = await _repo.add(variantId: variantId, quantity: quantity);
      _cart = m.cart;
      _warning = m.warning;
      _errorMessage = null;
      _status = CartStatus.ready;
      await _persistSummary();
      return true;
    } on AuthException catch (e) {
      _cart = snapshot;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _cart = snapshot;
      _errorMessage = e.toString();
      return false;
    } finally {
      _isBusy = false;
      _safeNotify();
    }
  }

  Future<bool> addBundle(int bundleId) async {
    _isBusy = true;
    _safeNotify();
    final snapshot = _cart;
    try {
      final m = await _repo.addBundle(bundleId);
      _cart = m.cart;
      _warning = m.warning;
      _errorMessage = null;
      _status = CartStatus.ready;
      await _persistSummary();
      return true;
    } on AuthException catch (e) {
      _cart = snapshot;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _cart = snapshot;
      _errorMessage = e.toString();
      return false;
    } finally {
      _isBusy = false;
      _safeNotify();
    }
  }

  /// Absolute value. `<= 0` routes to remove (mirrors the server).
  void setQuantity(int cartItemId, int quantity) {
    if (quantity < 1) {
      remove(cartItemId);
      return;
    }
    _pendingItemIds.add(cartItemId);
    _safeNotify();
    _debounce[cartItemId]?.cancel();
    _debounce[cartItemId] = Timer(const Duration(milliseconds: 400), () {
      _debounce.remove(cartItemId);
      _sendQuantity(cartItemId, quantity);
    });
  }

  Future<void> _sendQuantity(int cartItemId, int quantity) async {
    final snapshot = _cart;
    try {
      final m = await _repo.setQuantity(cartItemId, quantity);
      _cart = m.cart;
      _warning = m.warning;
      _errorMessage = null;
      await _persistSummary();
    } on AuthException catch (e) {
      _cart = snapshot;
      _errorMessage = e.message;
    } catch (e) {
      _cart = snapshot;
      _errorMessage = e.toString();
    } finally {
      _pendingItemIds.remove(cartItemId);
      _safeNotify();
    }
  }

  Future<bool> remove(int cartItemId) async {
    _debounce.remove(cartItemId)?.cancel();
    final snapshot = _cart;
    _pendingItemIds.add(cartItemId);
    _safeNotify();
    try {
      final m = await _repo.remove(cartItemId);
      _cart = m.cart;
      _warning = m.warning;
      _errorMessage = null;
      await _persistSummary();
      return true;
    } on AuthException catch (e) {
      // Stale cart_item_id: refresh so we don't leave a dead row.
      _cart = snapshot;
      _errorMessage = e.message;
      unawaited(refresh());
      return false;
    } catch (e) {
      _cart = snapshot;
      _errorMessage = e.toString();
      return false;
    } finally {
      _pendingItemIds.remove(cartItemId);
      _safeNotify();
    }
  }

  Future<void> clear() async {
    _isBusy = true;
    _safeNotify();
    final snapshot = _cart;
    try {
      final m = await _repo.clear();
      _cart = m.cart;
      _warning = m.warning;
      _errorMessage = null;
      await _persistSummary();
    } on AuthException catch (e) {
      _cart = snapshot;
      _errorMessage = e.message;
    } catch (e) {
      _cart = snapshot;
      _errorMessage = e.toString();
    } finally {
      _isBusy = false;
      _safeNotify();
    }
  }

  void reset() {
    for (final t in _debounce.values) {
      t.cancel();
    }
    _debounce.clear();
    _pendingItemIds.clear();
    _cart = Cart.empty;
    _status = CartStatus.idle;
    _errorMessage = null;
    _warning = null;
    _isBusy = false;
    _cachedCount = null;
    _cachedTotal = null;
    _seq++;
    SharedPreferences.getInstance().then((p) => p.remove(_summaryKey));
    _safeNotify();
  }

  Future<void> _hydrateCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_summaryKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _cachedCount = (decoded['count'] as num?)?.toInt();
      _cachedTotal = (decoded['total'] as num?)?.toDouble();
    } catch (_) {/* ignored: cache is best-effort */}
  }

  Future<void> _persistSummary() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _summaryKey,
        jsonEncode({'count': _cart.itemCount, 'total': _cart.total}),
      );
      _cachedCount = _cart.itemCount;
      _cachedTotal = _cart.total;
    } catch (_) {/* ignored */}
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _debounce.values) {
      t.cancel();
    }
    _debounce.clear();
    super.dispose();
  }
}