// lib/models/order.dart
import '../core/format.dart';
import 'order_item.dart';
import 'order_payment.dart';
import 'order_shipping.dart';
import 'order_status_event.dart';

class Order {
  final int orderId;
  final int? couponId;
  final int? shippingMethodId;
  final String? shippingMethodName;
  final double subtotal, discountAmount, shippingFee, tax, totalAmount;
  final String status;
  final int itemCount;
  final DateTime? createdAt;
  final OrderPayment? payment;
  final OrderShipping? shipping;
  final List<OrderStatusEvent> history;
  final List<OrderItem> items;

  const Order({
    required this.orderId,
    this.couponId,
    this.shippingMethodId,
    this.shippingMethodName,
    this.subtotal = 0,
    this.discountAmount = 0,
    this.shippingFee = 0,
    this.tax = 0,
    this.totalAmount = 0,
    this.status = 'Pending',
    this.itemCount = 0,
    this.createdAt,
    this.payment,
    this.shipping,
    this.history = const [],
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return Order(
      orderId: json['order_id'] as int,
      couponId: json['coupon_id'] as int?,
      shippingMethodId: json['shipping_method_id'] as int?,
      shippingMethodName: json['shipping_method'] as String?,
      subtotal: d('subtotal'),
      discountAmount: d('discount_amount'),
      shippingFee: d('shipping_fee'),
      tax: d('tax'),
      totalAmount: d('total_amount'),
      status: (json['status'] as String?) ?? 'Pending',
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      createdAt: parseServerDate(json['created_at'] as String?),
      payment: json['payment'] == null
          ? null
          : OrderPayment.fromJson(json['payment'] as Map<String, dynamic>),
      shipping: json['shipping'] == null
          ? null
          : OrderShipping.fromJson(json['shipping'] as Map<String, dynamic>),
      history: (json['status_history'] as List?)
              ?.map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}