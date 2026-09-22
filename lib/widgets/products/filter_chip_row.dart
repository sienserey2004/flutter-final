import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class RemovableChip {
  final String label;
  final VoidCallback onRemove;
  const RemovableChip({required this.label, required this.onRemove});
}

class FilterChipRow extends StatelessWidget {
  final List<RemovableChip> chips;
  final VoidCallback? onClearAll;

  const FilterChipRow({super.key, required this.chips, this.onClearAll});

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length + (onClearAll != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (onClearAll != null && i == chips.length) {
            return Center(
              child: TextButton(
                onPressed: onClearAll,
                child: const Text('Clear all'),
              ),
            );
          }
          final c = chips[i];
          return Center(
            child: InputChip(
              label: Text(c.label),
              onDeleted: c.onRemove,
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
            ),
          );
        },
      ),
    );
  }
}