// lib/orders/checkout_controller.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';
import '../models/address.dart';
import '../models/checkout_quote.dart';
import '../models/order.dart';
import '../models/shipping_option.dart';
import 'address_repository.dart';
import 'order_repository.dart';

enum CheckoutStatus { loading, ready, error, submitting }

sealed class PlaceOutcome {
  const PlaceOutcome();
}

class Placed extends PlaceOutcome {
  final PlaceOrderResult result;
  final bool paymentUnavailable;
  const Placed(this.result, {this.paymentUnavailable = false});
}

class StockConflict extends PlaceOutcome {
  final String message;
  const StockConflict(this.message);
}

class InvalidDetails extends PlaceOutcome {
  final String message;
  const InvalidDetails(this.message);
}

class EmptyCart extends PlaceOutcome {
  final String message;
  const EmptyCart(this.message);
}

class PlaceFailed extends PlaceOutcome {
  final String message;
  const PlaceFailed(this.message);
}

class CheckoutDraft {
  final int? selectedMethodId;
  final int? selectedAddressId;
  final int? couponId;
  final String paymentMethod;
  final String name;
  final String line1;
  final String city;
  final String phone;
  final String postalCode;
  final String country;

  const CheckoutDraft({
    required this.selectedMethodId,
    required this.selectedAddressId,
    required this.couponId,
    required this.paymentMethod,
    required this.name,
    required this.line1,
    required this.city,
    required this.phone,
    required this.postalCode,
    required this.country,
  });

  Map<String, dynamic> toRequest() => {
        'action': 'place_order',
        'shipping_method_id': selectedMethodId,
        if (couponId != null) 'coupon_id': couponId,
        'payment_method': paymentMethod,
        if (selectedAddressId != null)
          'address_id': selectedAddressId
        else ...{
          'recipient_name': name,
          'address': line1, // NOT 'line1' — the order endpoint names it 'address'
          'city': city,
          'phone': phone,
          if (postalCode.isNotEmpty) 'postal_code': postalCode,
          'country': country.isEmpty ? 'Cambodia' : country,
        },
      };
}

class CheckoutController extends ChangeNotifier {
  CheckoutController({required ApiClient api}) : _repo = OrderRepository(api);

  final OrderRepository _repo;

  CheckoutStatus _status = CheckoutStatus.loading;
  CheckoutBootstrap? _bootstrap;
  Quote _quote = Quote.empty;
  String? _errorMessage;

  int? _selectedMethodId;
  int? _selectedAddressId;
  bool _useNewAddress = false;
  String _couponCode = '';
  int? _couponId;
  String _paymentMethod = 'Cash';
  bool _busy = false;
  bool _placed = false;

  // New-address form fields (also used for validation).
  String newRecipient = '';
  String newPhone = '';
  String newLine1 = '';
  String newCity = '';
  String newPostal = '';
  String newCountry = 'Cambodia';
  bool saveAddress = true;

  Timer? _repriceTimer;
  bool _repricePending = false;

  CheckoutStatus get status => _status;
  CheckoutBootstrap? get bootstrap => _bootstrap;
  Quote get quote => _quote;
  String? get errorMessage => _errorMessage;
  int? get selectedMethodId => _selectedMethodId;
  List<Address> get addresses => _bootstrap?.addresses ?? const [];
  int? get selectedAddressId => _selectedAddressId;
  bool get useNewAddress => _useNewAddress;
  String get couponCode => _couponCode;
  int? get couponId => _couponId;
  String get paymentMethod => _paymentMethod;
  bool get isBusy => _busy;
  bool get isRepricing => _repricePending;

  bool get _addressValid {
    if (!_useNewAddress) return _selectedAddressId != null;
    return newRecipient.trim().isNotEmpty &&
        newPhone.trim().isNotEmpty &&
        newLine1.trim().isNotEmpty &&
        newCity.trim().isNotEmpty;
  }

  bool get canPlaceOrder =>
      _status == CheckoutStatus.ready && _addressValid && !_busy && !_placed;

  Future<void> load() async {
    _status = CheckoutStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final b = await _repo.loadCheckout();
      _bootstrap = b;
      _quote = b.quote;
      _selectedMethodId = b.shippingMethods.isNotEmpty
          ? b.shippingMethods.first.methodId
          : null;
      _selectedAddressId = b.addresses.isNotEmpty
          ? (b.addresses.firstWhere((a) => a.isDefault,
              orElse: () => b.addresses.first)).addressId
          : null;
      _useNewAddress = b.addresses.isEmpty;
      _status = CheckoutStatus.ready;
    } on ApiException catch (e) {
      if (e.status == 422) {
        _errorMessage = e.message;   // 'Your cart is empty.' — screen pops back
        _status = CheckoutStatus.error;
      } else {
        _errorMessage = e.message;
        _status = CheckoutStatus.error;
      }
    } catch (e) {
      _errorMessage = 'Could not reach the server.';
      _status = CheckoutStatus.error;
    }
    notifyListeners();
  }

  void selectMethod(int id) {
    if (_selectedMethodId == id) return;
    _selectedMethodId = id;
    notifyListeners();
    _repriceTimer?.cancel();
    _repriceTimer = Timer(const Duration(milliseconds: 350), () => _reprice());
  }

  void selectAddress(int? id) {
    _useNewAddress = id == null;
    _selectedAddressId = id;
    notifyListeners();
  }

  Future<bool> applyCoupon(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty || _selectedMethodId == null) return false;
    _busy = true;
    notifyListeners();
    try {
      final result = await _repo.applyCoupon(trimmed, _selectedMethodId!);
      _quote = result.quote;
      _couponCode = result.couponCode ?? trimmed;
      _couponId = result.couponId;
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not apply the coupon.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> removeCoupon() async {
    _couponCode = '';
    _couponId = null;
    if (_selectedMethodId == null) {
      notifyListeners();
      return;
    }
    await _reprice(clearCoupon: true);
  }

  void updatePaymentMethod(String value) {
    _paymentMethod = value;
    notifyListeners();
  }

  Future<void> _reprice({bool clearCoupon = false}) async {
    if (_selectedMethodId == null) return;
    _repricePending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repo.reprice(
        methodId: _selectedMethodId,
        couponCode: clearCoupon ? '' : _couponCode,
      );
      _quote = result.quote;
      if (clearCoupon) {
        _couponCode = '';
        _couponId = null;
      } else {
        _couponId = result.couponId ?? _couponId;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not update delivery pricing.';
    } finally {
      _repricePending = false;
      notifyListeners();
    }
  }

  Future<PlaceOutcome> placeOrder() async {
    if (!canPlaceOrder) return const PlaceFailed('Cannot place order.');
    _busy = true;
    _status = CheckoutStatus.submitting;
    notifyListeners();
    final draft = CheckoutDraft(
      selectedMethodId: _selectedMethodId,
      selectedAddressId: _useNewAddress ? null : _selectedAddressId,
      couponId: _couponId,
      paymentMethod: _paymentMethod,
      name: newRecipient,
      line1: newLine1,
      city: newCity,
      phone: newPhone,
      postalCode: newPostal,
      country: newCountry,
    );
    try {
      final result = await _repo.placeOrder(draft.toRequest());
      _placed = true;

      // Fire-and-forget save this address
      if (_useNewAddress && saveAddress) {
        try {
          await AddressRepository(_repo.api).create(AddressDraft(
            recipientName: newRecipient,
            phone: newPhone,
            line1: newLine1,
            city: newCity,
            postalCode: newPostal,
            country: newCountry,
          ));
        } catch (_) {/* order already exists; ignore */}
      }

      return Placed(result);
    } on ApiException catch (e) {
      if (e.status == 409) return StockConflict(e.message);
      if (e.status == 422) {
        final orderJson = e.payload['order'] as Map<String, dynamic>?;
        if (orderJson != null && orderJson.containsKey('order_id')) {
          return Placed(
            PlaceOrderResult(
              order: Order.fromJson(orderJson),
              paymentUnavailable: true,
            ),
            paymentUnavailable: true,
          );
        }
        if (e.message.toLowerCase().contains('cart is empty')) {
          return EmptyCart(e.message);
        }
        return InvalidDetails(e.message);
      }
      return PlaceFailed(e.message);
    } catch (_) {
      return const PlaceFailed('Could not reach the server.');
    } finally {
      _busy = false;
      if (!_placed) _status = CheckoutStatus.ready;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repriceTimer?.cancel();
    super.dispose();
  }
}