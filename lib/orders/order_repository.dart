// lib/orders/order_repository.dart
import '../auth/auth_controller.dart';
import '../models/checkout_quote.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../models/shipping_option.dart';

class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;
  ApiClient get api => _api;

  Future<List<Order>> history() async {
    final data = await _api.request('/orders/');
    final list = (data as List?) ?? const [];
    return list
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Order> order(int orderId) async {
    final data = await _api.request('/orders/$orderId');
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<CheckoutBootstrap> loadCheckout() async {
    final data = await _api.request('/orders/checkout') as Map<String, dynamic>;
    final cart = (data['cart'] as Map<String, dynamic>?) ?? const {};
    final items = (cart['items'] as List?) ?? const [];
    final addresses = (data['addresses'] as List?)
            ?.map((e) => Address.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <Address>[];
    final methods = (data['shipping_methods'] as List?)
            ?.map((e) => ShippingOption.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <ShippingOption>[];
    return CheckoutBootstrap(
      cartItems: items,
      cartItemCount: (cart['item_count'] as num?)?.toInt() ?? items.length,
      addresses: addresses,
      shippingMethods: methods,
      couponCode: data['coupon_code'] as String?,
      quote: Quote.fromFlatJson(data),
    );
  }

  Future<QuoteResult> reprice({
    int? methodId,
    String couponCode = '',
  }) async {
    final data = await _api.request('/orders/checkout', method: 'POST', body: {
      'action': 'update_shipping',
      if (methodId != null) 'shipping_method_id': methodId,
      'coupon_code': couponCode,
    }) as Map<String, dynamic>;
    return _quoteResult(data);
  }

  Future<QuoteResult> applyCoupon(String code, int methodId) async {
    final data = await _api.request('/orders/checkout', method: 'POST', body: {
      'action': 'apply_coupon',
      'coupon_code': code,
      'shipping_method_id': methodId,
    }) as Map<String, dynamic>;
    return _quoteResult(data);
  }

  QuoteResult _quoteResult(Map<String, dynamic> data) {
    final coupon = data['coupon'] as Map<String, dynamic>?;
    return QuoteResult(
      quote: Quote.fromFlatJson(data),
      couponCode: data['coupon_code'] as String?,
      couponId: coupon?['coupon_id'] as int?,
    );
  }

  Future<PlaceOrderResult> placeOrder(Map<String, dynamic> body) async {
    final data = await _api.request('/orders/checkout', method: 'POST', body: body);
    // Rule 1: a 200 with no 'order' key means the POST fell through.
    if (data is! Map<String, dynamic>) {
      throw const ApiException('The server did not accept the order.');
    }
    // Rule 2: KHQR wraps the order in {order, transaction}.
    final hasOrder = data.containsKey('order');
    final orderJson = hasOrder
        ? data['order'] as Map<String, dynamic>?
        : data as Map<String, dynamic>;
    if (orderJson == null || !orderJson.containsKey('order_id')) {
      throw const ApiException('The server did not accept the order.');
    }
    final order = Order.fromJson(orderJson);
    final txJson = data['transaction'] as Map<String, dynamic>?;
    return PlaceOrderResult(
      order: order,
      transaction: txJson == null
          ? null
          : PaymentTransactionInfo.fromJson(txJson),
    );
  }

  Future<KhqrPayment> khqr(int txId) async {
    final data =
        await _api.request('/orders/khqr-payment/$txId') as Map<String, dynamic>;
    return KhqrPayment(
      transaction: PaymentTransactionInfo.fromJson(
          data['transaction'] as Map<String, dynamic>),
      qrBase64: data['qr_base64'] as String? ?? '',
      deeplink: data['deeplink'] as String?,
    );
  }

  /// NOTE: `/api/orders` is the blueprint prefix and the route is `/api/check-payment`,
  /// so the full path really is `/orders/api/check-payment`.
  Future<PaymentPoll> pollPayment(String md5) async {
    try {
      // The poll response is NOT the envelope — we read it as a raw map.
      final data = await _api.request('/orders/api/check-payment',
          method: 'POST', body: {'md5': md5});
      final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
      final status = (map['status'] as String?)?.toLowerCase();
      if (status == 'paid') return const PaymentPoll(PaymentPollStatus.paid);
      if (status == 'failed' || status == 'expired') {
        return PaymentPoll(PaymentPollStatus.transientError,
            message: map['message'] as String?);
      }
      return const PaymentPoll(PaymentPollStatus.pending);
    } on ApiException catch (e) {
      return PaymentPoll(PaymentPollStatus.transientError, message: e.message);
    }
  }
}
