// lib/orders/orders_controller.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';
import '../models/order.dart';
import 'order_repository.dart';

enum OrdersStatus { loading, error, ready }

class OrdersController extends ChangeNotifier {
  OrdersController({required ApiClient api}) : _repo = OrderRepository(api);

  final OrderRepository _repo;
  OrdersStatus _status = OrdersStatus.loading;
  List<Order> _orders = const [];
  String? _error;
  String _filter = 'All';
  final Map<int, Order> _details = {};

  OrdersStatus get status => _status;
  List<Order> get orders {
    if (_filter == 'All') return _orders;
    return _orders.where((o) => o.status == _filter).toList(growable: false);
  }
  List<Order> get allOrders => _orders;
  String? get error => _error;
  String get filter => _filter;
  Order? cachedDetail(int id) => _details[id];

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  Future<void> load() async {
    _status = OrdersStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repo.history();
      _status = OrdersStatus.ready;
    } on ApiException catch (e) {
      _error = e.message;
      _status = _orders.isEmpty ? OrdersStatus.error : OrdersStatus.ready;
    } catch (_) {
      _error = 'Could not reach the server.';
      _status = _orders.isEmpty ? OrdersStatus.error : OrdersStatus.ready;
    }
    notifyListeners();
  }

  Future<Order> open(int id) async {
    final cached = _details[id];
    final fresh = await _repo.order(id);
    _details[id] = fresh;
    notifyListeners();
    return fresh;
  }

  Future<Order> refreshDetail(int id) async {
    final fresh = await _repo.order(id);
    _details[id] = fresh;
    final i = _orders.indexWhere((o) => o.orderId == id);
    if (i >= 0) {
      final list = [..._orders];
      list[i] = fresh;
      _orders = list;
    }
    notifyListeners();
    return fresh;
  }

  void forget(int id) {
    _details.remove(id);
  }
}