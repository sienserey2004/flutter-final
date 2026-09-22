// lib/screens/orders/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/checkout_quote.dart';
import '../../models/order.dart';
import '../../widgets/app_button.dart';
import '../../widgets/order_status_badge.dart';
import 'khqr_payment_screen.dart';
import 'order_detail_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.transaction,
    this.paymentUnavailable = false,
  });
  final Order order;
  final PaymentTransactionInfo? transaction;
  final bool paymentUnavailable;

  @override
  Widget build(BuildContext context) {
    final showKhqr = transaction != null && !paymentUnavailable;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Order'),
          automaticallyImplyLeading: false,
        ),
        body: ListView(children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 44, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Order placed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Order #${order.orderId} · ${formatOrderDate(order.createdAt)}',
              style: const TextStyle(
                  fontFamily: 'monospace', color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: OrderStatusBadge(order.status)),
          if (paymentUnavailable)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Online payment is unavailable right now. Pay on delivery.',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          _totals(),
          if (order.shipping != null)
            _section('Delivery', [
              if (order.shipping!.recipientName != null)
                Text(order.shipping!.recipientName!),
              Text(order.shipping!.oneLine,
                  style: const TextStyle(color: AppColors.textSecondary)),
              if (order.shippingMethodName != null)
                Text(order.shippingMethodName!,
                    style: const TextStyle(fontSize: 12)),
            ]),
          if (order.payment != null)
            _section('Payment', [
              Text('${order.payment!.method} · ${order.payment!.status}'),
              if (order.payment!.method == 'Cash')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Pay the courier in cash — have ${formatPrice(order.totalAmount)} ready.',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
            ]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (showKhqr)
                AppButton(
                  label: 'Pay now with KHQR',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KhqrPaymentScreen(
                        orderId: order.orderId,
                        txId: transaction!.transactionId,
                      ),
                    ),
                  ),
                ),
              if (showKhqr) const SizedBox(height: 8),
              AppButton(
                label: 'View order details',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderDetailScreen(orderId: order.orderId, initial: order),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((r) => r.isFirst),
                child: const Text('Continue shopping'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _totals() => Card(
        margin: const EdgeInsets.all(16),
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _row('Subtotal', formatPrice(order.subtotal)),
            if (order.discountAmount > 0)
              _row('Discount', '−${formatPrice(order.discountAmount)}',
                  color: AppColors.primary),
            _row(
                'Delivery',
                order.shippingFee == 0
                    ? 'FREE'
                    : formatPrice(order.shippingFee),
                color: order.shippingFee == 0 ? AppColors.primary : null),
            if (order.tax > 0) _row('Tax', formatPrice(order.tax)),
            const Divider(),
            Row(children: [
              const Expanded(
                  child: Text('Total',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              Text(formatPrice(order.totalAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
          ]),
        ),
      );

  Widget _section(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Widget _row(String l, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
              child: Text(l,
                  style: const TextStyle(color: AppColors.textSecondary))),
          Text(v,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}