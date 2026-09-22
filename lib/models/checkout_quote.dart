// lib/models/checkout_quote.dart
import 'address.dart';
import 'order.dart';
import 'shipping_option.dart';

class Quote {
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double tax;
  final double total;

  const Quote({
    this.subtotal = 0,
    this.discount = 0,
    this.shippingFee = 0,
    this.tax = 0,
    this.total = 0,
  });

  double get afterDiscount => subtotal - discount;

  static const empty = Quote();

  /// `GET /orders/checkout` and both re-pricing POSTs spread the quote flat
  /// into `data` alongside other keys — there is never a `data['quote']`.
  factory Quote.fromFlatJson(Map<String, dynamic> json) {
    double d(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return Quote(
      subtotal: d('subtotal'),
      discount: d('discount'),
      shippingFee: d('shipping_fee'),
      tax: d('tax'),
      total: d('total'),
    );
  }
}

class CheckoutBootstrap {
  final List<dynamic> cartItems;   // Plan 3 CartItem
  final int cartItemCount;
  final List<Address> addresses;
  final List<ShippingOption> shippingMethods;
  final String? couponCode;
  final Quote quote;

  const CheckoutBootstrap({
    required this.cartItems,
    required this.cartItemCount,
    required this.addresses,
    required this.shippingMethods,
    this.couponCode,
    required this.quote,
  });
}

class PaymentTransactionInfo {
  final int transactionId;
  final String md5Hash;
  final double amount;
  final String currency;
  final String status;

  const PaymentTransactionInfo({
    required this.transactionId,
    required this.md5Hash,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory PaymentTransactionInfo.fromJson(Map<String, dynamic> json) =>
      PaymentTransactionInfo(
        transactionId: json['transaction_id'] as int,
        md5Hash: json['md5_hash'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'USD',
        status: json['status'] as String? ?? 'Pending',
      );
}

class PlaceOrderResult {
  final Order order;
  final PaymentTransactionInfo? transaction;
  final bool paymentUnavailable;

  const PlaceOrderResult({
    required this.order,
    this.transaction,
    this.paymentUnavailable = false,
  });
}

class QuoteResult {
  final Quote quote;
  final String? couponCode;
  final int? couponId;
  const QuoteResult({required this.quote, this.couponCode, this.couponId});
}

class KhqrPayment {
  final PaymentTransactionInfo transaction;
  final String qrBase64;
  final String? deeplink;
  const KhqrPayment({
    required this.transaction,
    required this.qrBase64,
    this.deeplink,
  });
}

enum PaymentPollStatus { paid, pending, transientError }

class PaymentPoll {
  final PaymentPollStatus status;
  final String? message;
  const PaymentPoll(this.status, {this.message});
}