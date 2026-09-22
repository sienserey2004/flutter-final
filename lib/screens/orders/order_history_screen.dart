// lib/screens/orders/order_history_screen.dart
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../orders/orders_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../../widgets/order_tile.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrdersController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = OrdersController(api: AuthScope.of(context, listen: false).api);
    _ctrl.load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.status == OrdersStatus.loading && _ctrl.allOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_ctrl.status == OrdersStatus.error && _ctrl.allOrders.isEmpty) {
            return ErrorStateView(
              message: 'Could not load your orders.',
              onRetry: _ctrl.load,
            );
          }
          final list = _ctrl.orders;
          return Column(children: [
            if (_ctrl.error != null)
              ErrorBanner(message: _ctrl.error!, onRetry: _ctrl.load),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = _ctrl.filter == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => _ctrl.setFilter(f),
                  );
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _ctrl.load,
                child: list.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No orders yet',
                          message:
                              'When you place an order it will show up here.',
                          action: AppButton(
                            label: 'Start shopping',
                            onPressed: () => Navigator.of(context)
                                .popUntil((r) => r.isFirst),
                          ),
                        ),
                      ])
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final o = list[i];
                          return OrderTile(
                            key: ValueKey(o.orderId),
                            order: o,
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  orderId: o.orderId,
                                  initial: o,
                                ),
                              ));
                              _ctrl.load();
                            },
                          );
                        },
                      ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
