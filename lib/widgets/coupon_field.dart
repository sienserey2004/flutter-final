// lib/widgets/coupon_field.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CouponField extends StatefulWidget {
  const CouponField({
    super.key,
    required this.appliedCode,
    required this.discountLabel,
    required this.onApply,
    required this.onRemove,
    this.enabled = true,
  });
  final String appliedCode;
  final String discountLabel;
  final Future<bool> Function(String code) onApply;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    final ok = await widget.onApply(code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appliedCode.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.local_offer_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.appliedCode} applied −${widget.discountLabel}',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled && !_busy,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Coupon code',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: widget.enabled && !_busy ? _apply : null,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Apply'),
          ),
        ),
      ]),
    );
  }
}