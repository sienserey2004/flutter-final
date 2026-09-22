// lib/screens/orders/khqr_payment_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/checkout_quote.dart';
import '../../orders/order_repository.dart';
import '../../widgets/qr_code_view.dart';

class KhqrPaymentScreen extends StatefulWidget {
  const KhqrPaymentScreen({super.key, required this.orderId, this.txId});
  final int orderId;
  final int? txId;

  @override
  State<KhqrPaymentScreen> createState() => _KhqrPaymentScreenState();
}

class _KhqrPaymentScreenState extends State<KhqrPaymentScreen> {
  late final OrderRepository _repo;
  KhqrPayment? _payment;
  String? _error;
  bool _busy = false;
  bool _paid = false;
  int _consecutiveErrors = 0;
  int _secondsLeft = 60;
  Timer? _pollTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _repo = OrderRepository(AuthScope.of(context, listen: false).api);
    _load();
  }

  Future<void> _load() async {
    int? txId = widget.txId;
    if (txId == null) {
      final prefs = await SharedPreferences.getInstance();
      txId = prefs.getInt('khqr_tx_${widget.orderId}');
    }
    if (txId == null) {
      setState(() => _error = 'No pending KHQR transaction for this order.');
      return;
    }
    try {
      final p = await _repo.khqr(txId);
      if (!mounted) return;
      setState(() {
        _payment = p;
        _error = null;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('khqr_tx_${widget.orderId}', txId!);
      _startTimers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load the KHQR code.');
    }
  }

  void _startTimers() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
      }
    });
  }

  Future<void> _poll() async {
    final p = _payment;
    if (p == null || _busy) return;
    setState(() => _busy = true);
    final r = await _repo.pollPayment(p.transaction.md5Hash);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r.status) {
      case PaymentPollStatus.paid:
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('khqr_tx_${widget.orderId}');
        if (!mounted) return;
        setState(() => _paid = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment received!')),
        );
        Navigator.of(context).pop();
      case PaymentPollStatus.pending:
        _consecutiveErrors = 0;
      case PaymentPollStatus.transientError:
        _consecutiveErrors++;
        if (_consecutiveErrors >= 3) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
        }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pay with KHQR')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final p = _payment;
    if (p == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Expanded(child: Text('Amount due')),
              Text(
                '${formatPrice(p.transaction.amount)} ${p.transaction.currency}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: QrCodeView(
            imageProvider: MemoryImage(base64Decode(p.qrBase64)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _paid
                ? 'Paid'
                : 'Expires in $minutes:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: _paid ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: _busy
              ? const CircularProgressIndicator()
              : Text(
                  _paid ? 'Paid' : 'Waiting for payment…',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _busy ? null : _poll,
            icon: const Icon(Icons.refresh),
            label: const Text('I have paid — check now'),
          ),
        ),
        if (p.deeplink != null && p.deeplink!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Or open your Bakong app and scan the code',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: SelectableText(p.deeplink!,
                  style: const TextStyle(fontSize: 12)),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: p.deeplink!));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deep link copied')));
              },
              icon: const Icon(Icons.copy, size: 18),
            ),
          ]),
        ],
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Pay later — back to order'),
        ),
      ],
    );
  }
}