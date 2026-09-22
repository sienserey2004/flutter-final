// lib/screens/orders/order_detail_screen.dart
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/order.dart';
import '../../orders/orders_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../../widgets/order_item_tile.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/status_timeline.dart';
import '../shopping/cart_screen.dart';
import 'khqr_payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.initial});
  final int orderId;
  final Order? initial;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final OrdersController _ctrl;
  Order? _order;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _ctrl = OrdersController(api: AuthScope.of(context, listen: false).api);
    _order = widget.initial ?? _ctrl.cachedDetail(widget.orderId);
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await _ctrl.refreshDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = o;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_order == null) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: ErrorStateView(
            message: 'This order is no longer available',
            onRetry: () {
              setState(() => _error = false);
              _load();
            }),
      );
    }
    final o = _order;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('#${o.orderId}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HeaderCard(order: o)),
            SliverToBoxAdapter(child: _ItemsCard(order: o)),
            SliverToBoxAdapter(child: _TotalsCard(order: o)),
            SliverToBoxAdapter(
              child: _sectionCard(
                title: 'Status',
                child: StatusTimeline(events: o.history),
              ),
            ),
            if (o.shipping != null)
              SliverToBoxAdapter(child: _DeliveryCard(order: o)),
            if (o.payment != null)
              SliverToBoxAdapter(child: _PaymentCard(order: o)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  AppButton(
                    label: 'Reorder',
                    onPressed: () => _reorder(o),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                    child: const Text('View cart'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary)),
        ),
        child,
      ]),
    );
  }

  Future<void> _reorder(Order o) async {
    final cart = AuthScope.of(context, listen: false).api;
    int added = 0;
    int skipped = 0;
    for (final item in o.items) {
      if (item.variant == null) {
        skipped++;
        continue;
      }
      try {
        await cart.request('/cart/add', method: 'POST', body: {
          'variant_id': item.variantId,
          'quantity': item.quantity,
        });
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$added of ${o.items.length} items added to your cart'),
    ));
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.orderId}',
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(formatOrderDateTime(order.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 6),
                Text(
                  '${order.itemCount} items · ${order.shippingMethodName ?? ''}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OrderStatusBadge(order.status),
        ]),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: order.items.map((e) => OrderItemTile(item: e)).toList(),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                valueColor: AppColors.primary),
          _row(
            'Delivery',
            order.shippingFee == 0 ? 'FREE' : formatPrice(order.shippingFee),
            valueColor:
                order.shippingFee == 0 ? AppColors.primary : null,
          ),
          if (order.tax > 0) _row('Tax', formatPrice(order.tax)),
          const Divider(height: 20),
          Row(children: [
            const Expanded(
                child: Text('Order total',
                    style: TextStyle(fontWeight: FontWeight.w700))),
            Text(formatPrice(order.totalAmount),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    final s = order.shipping!;
    return Card(
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
            Row(children: [
              const Expanded(
                  child: Text('Delivery',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              if (s.status != null) OrderStatusBadge(s.status!),
            ]),
            const SizedBox(height: 8),
            if (s.recipientName != null) Text(s.recipientName!),
            if (s.phone != null) Text(s.phone!),
            if (s.oneLine.isNotEmpty)
              Text(s.oneLine,
                  style: const TextStyle(color: AppColors.textSecondary)),
            if (s.carrier != null && s.trackingNumber != null) ...[
              const SizedBox(height: 8),
              Text('${s.carrier} · ${s.trackingNumber}',
                  style: const TextStyle(fontSize: 13)),
            ],
            if (s.shippedAt != null || s.deliveredAt != null) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (s.shippedAt != null)
                    'Shipped ${formatOrderDate(s.shippedAt)}',
                  if (s.deliveredAt != null)
                    'Delivered ${formatOrderDate(s.deliveredAt)}',
                ].join(' · '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    final p = order.payment!;
    final canResume = p.method == 'KHQR' && p.status == 'Pending';
    return Card(
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
            Row(children: [
              const Expanded(
                  child: Text('Payment',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              OrderStatusBadge(p.status),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(p.method)),
              Text(formatPrice(p.amount),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            if (p.paidAt != null) ...[
              const SizedBox(height: 4),
              Text('Paid ${formatOrderDateTime(p.paidAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ],
            if (canResume) ...[
              const SizedBox(height: 10),
              AppButton(
                label: 'Resume payment',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KhqrPaymentScreen(orderId: order.orderId),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
