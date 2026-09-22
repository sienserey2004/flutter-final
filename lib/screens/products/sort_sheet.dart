import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/filter_options.dart';
import '../../models/product_filter.dart';

class SortSheet {
  static Future<ProductSort?> show(
    BuildContext context, {
    required ProductSort current,
    FilterOptions options = FilterOptions.empty,
  }) {
    final entries = options.sorts.isNotEmpty
        ? options.sorts.entries.toList()
        : ProductSort.values
            .map((s) => MapEntry(s.queryValue, s.label))
            .toList();

    return showModalBottomSheet<ProductSort>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.s,
                ),
                child: Row(
                  children: const [
                    Text(
                      'Sort by',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              for (final entry in entries)
                RadioListTile<ProductSort>(
                  value: ProductSort.fromQueryValue(entry.key),
                  groupValue: current,
                  title: Text(entry.value),
                  onChanged: (v) => Navigator.of(ctx).pop(v),
                ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        );
      },
    );
  }
}