import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `onChanged(0)` signals "remove this line" (mirrors the server's `qty < 1`).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.min,
    required this.max,
    required this.onChanged,
    this.enabled = true,
  });

  final int quantity;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool enabled;

  void _dec() {
    if (quantity <= min) {
      onChanged(0);
    } else {
      onChanged(quantity - 1);
    }
  }

  void _inc() {
    if (quantity >= max) return;
    onChanged(quantity + 1);
  }

  Future<void> _edit(BuildContext context) async {
    final ctrl = TextEditingController(text: '$quantity');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quantity'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text);
              if (n == null) return;
              Navigator.pop(ctx, n);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result < 1) {
      onChanged(0);
      return;
    }
    onChanged(result.clamp(1, max));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Quantity $quantity of $max',
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove,
              onTap: enabled ? _dec : null,
              semanticLabel: 'Decrease',
            ),
            GestureDetector(
              onLongPress: enabled ? () => _edit(context) : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                alignment: Alignment.center,
                child: Text(
                  '$quantity',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: enabled && quantity < max ? _inc : null,
              semanticLabel: 'Increase',
              tooltip: enabled && quantity >= max ? 'Max stock reached' : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}