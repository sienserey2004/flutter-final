// lib/screens/orders/checkout_screen.dart
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/address.dart';
import '../../orders/checkout_controller.dart';
import '../../shopping/cart_scope.dart';
import '../../widgets/address_fields.dart';
import '../../widgets/app_button.dart';
import '../../widgets/coupon_field.dart';
import '../../widgets/delivery_method_tile.dart';
import '../../widgets/state_views.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final CheckoutController _ctrl;

  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController(text: 'Cambodia');
  bool _saveAddress = true;

  @override
  void initState() {
    super.initState();
    final auth = AuthScope.of(context, listen: false);
    _ctrl = CheckoutController(api: auth.api);
    _recipient.text = auth.user?.name ?? '';
    _phone.text = auth.user?.phone ?? '';
    _ctrl.load().then((_) {
      if (!mounted) return;
      if (_ctrl.errorMessage?.toLowerCase().contains('cart is empty') ==
          true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_ctrl.errorMessage!)));
          Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _recipient.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    _ctrl.newRecipient = _recipient.text;
    _ctrl.newPhone = _phone.text;
    _ctrl.newLine1 = _line1.text;
    _ctrl.newCity = _city.text;
    _ctrl.newPostal = _postal.text;
    _ctrl.newCountry = _country.text;
    _ctrl.saveAddress = _saveAddress;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cart = CartScope.of(context, listen: false);

    final outcome = await _ctrl.placeOrder();
    if (!mounted) return;

    switch (outcome) {
      case Placed r:
        cart.refresh();
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            order: r.result.order,
            transaction: r.result.transaction,
            paymentUnavailable: r.paymentUnavailable,
          ),
        ));
      case StockConflict m:
        cart.refresh();
        messenger.showSnackBar(SnackBar(content: Text(m.message)));
        navigator.pop();
      case InvalidDetails m:
        messenger.showSnackBar(SnackBar(content: Text(m.message)));
      case EmptyCart m:
        messenger.showSnackBar(SnackBar(content: Text(m.message)));
        navigator.pop();
      case PlaceFailed m:
        messenger.showSnackBar(SnackBar(content: Text(m.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        if (_ctrl.status == CheckoutStatus.loading && _ctrl.bootstrap == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Checkout')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (_ctrl.status == CheckoutStatus.error && _ctrl.bootstrap == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Checkout')),
            body: ErrorStateView(
              message: 'Could not load checkout.',
              onRetry: _ctrl.load,
            ),
          );
        }
        final b = _ctrl.bootstrap!;
        return PopScope(
          canPop: !_ctrl.isBusy,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Checkout')),
            body: Column(children: [
              if (_ctrl.errorMessage != null)
                ErrorBanner(message: _ctrl.errorMessage!),
              if (_ctrl.isRepricing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: AbsorbPointer(
                  absorbing: _ctrl.isBusy,
                  child: Opacity(
                    opacity: _ctrl.isBusy ? 0.7 : 1,
                    child: ListView(children: [
                      _itemsCard(b.cartItemCount, _ctrl.quote.subtotal),
                      _deliveryCard(b.addresses),
                      _methodCard(b.shippingMethods),
                      CouponField(
                        appliedCode: _ctrl.couponCode,
                        discountLabel: formatPrice(_ctrl.quote.discount),
                        onApply: _ctrl.applyCoupon,
                        onRemove: _ctrl.removeCoupon,
                        enabled: !_ctrl.isBusy,
                      ),
                      _paymentCard(),
                      _summaryCard(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ),
            ]),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AppButton(
                  label:
                      'Place order · ${formatPrice(_ctrl.quote.total)}',
                  isLoading: _ctrl.isBusy,
                  onPressed:
                      _ctrl.canPlaceOrder ? _placeOrder : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            child,
          ],
        ),
      );

  Widget _itemsCard(int count, double subtotal) => _sectionCard(
        title: '$count items · ${formatPrice(subtotal)}',
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('—', style: TextStyle(color: AppColors.textTertiary)),
        ),
      );

  Widget _deliveryCard(List<Address> addresses) => _sectionCard(
        title: 'Delivery',
        child: Column(children: [
          ...addresses.map((a) => RadioListTile<int>(
                value: a.addressId,
                groupValue:
                    _ctrl.useNewAddress ? null : _ctrl.selectedAddressId,
                onChanged: (v) => _ctrl.selectAddress(v),
                title: Row(children: [
                  Text(a.recipientName),
                  if (a.isDefault) ...[
                    const SizedBox(width: 6),
                    const Text('· Default',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.success)),
                  ]
                ]),
                subtitle: Text(a.oneLine, maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              )),
          RadioListTile<int>(
            value: -1,
            groupValue:
                _ctrl.useNewAddress ? -1 : _ctrl.selectedAddressId,
            onChanged: (_) => _ctrl.selectAddress(null),
            title: const Text('Use a new address'),
          ),
          if (_ctrl.useNewAddress)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                AddressFields(
                  recipient: _recipient,
                  phone: _phone,
                  line1: _line1,
                  line2: _line2,
                  city: _city,
                  state: _state,
                  postal: _postal,
                  country: _country,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _saveAddress,
                  onChanged: (v) => setState(() => _saveAddress = v),
                  title: const Text('Save to my addresses'),
                ),
              ]),
            ),
        ]),
      );

  Widget _methodCard(List<dynamic> methods) => _sectionCard(
        title: 'Delivery method',
        child: Column(
          children: methods
              .map<Widget>((m) => DeliveryMethodTile(
                    option: m,
                    selected: _ctrl.selectedMethodId == m.methodId,
                    onTap: () => _ctrl.selectMethod(m.methodId),
                    afterDiscount: _ctrl.quote.afterDiscount,
                  ))
              .toList(),
        ),
      );

  Widget _paymentCard() => _sectionCard(
        title: 'Payment',
        child: Column(children: [
          RadioListTile<String>(
            value: 'Cash',
            groupValue: _ctrl.paymentMethod,
            onChanged: (v) => _ctrl.updatePaymentMethod(v!),
            title: const Text('Cash on delivery'),
          ),
          RadioListTile<String>(
            value: 'KHQR',
            groupValue: _ctrl.paymentMethod,
            onChanged: (v) => _ctrl.updatePaymentMethod(v!),
            title: const Text('KHQR · Bakong'),
          ),
        ]),
      );

  Widget _summaryCard() {
    final q = _ctrl.quote;
    return _sectionCard(
      title: 'Summary',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(children: [
          _row('Subtotal', formatPrice(q.subtotal)),
          if (q.discount > 0)
            _row('Discount', '−${formatPrice(q.discount)}',
                color: AppColors.primary),
          _row('Delivery',
              q.shippingFee == 0 ? 'FREE' : formatPrice(q.shippingFee),
              color: q.shippingFee == 0 ? AppColors.primary : null),
          if (q.tax > 0) _row('Tax', formatPrice(q.tax)),
          const Divider(height: 20),
          Row(children: [
            const Expanded(
                child: Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w700))),
            Text(formatPrice(q.total),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
        ]),
      ),
    );
  }

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
