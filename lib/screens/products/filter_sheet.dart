import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/filter_options.dart';
import '../../models/product_filter.dart';

class FilterSheet {
  static Future<ProductFilter?> show(
    BuildContext context, {
    required ProductFilter current,
    required FilterOptions options,
    int? originalCategoryId,
    String? originalCategoryTitle,
  }) {
    return showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) => _FilterSheetBody(
        current: current,
        options: options,
        originalCategoryId: originalCategoryId,
        originalCategoryTitle: originalCategoryTitle,
      ),
    );
  }
}

class _FilterSheetBody extends StatefulWidget {
  final ProductFilter current;
  final FilterOptions options;
  final int? originalCategoryId;
  final String? originalCategoryTitle;

  const _FilterSheetBody({
    required this.current,
    required this.options,
    this.originalCategoryId,
    this.originalCategoryTitle,
  });

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  late ProductFilter _draft;
  final TextEditingController _ingredientSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  @override
  void dispose() {
    _ingredientSearch.dispose();
    super.dispose();
  }

  void _update(ProductFilter f) => setState(() => _draft = f);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.s,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (!_draft.isEmpty)
                TextButton(
                  onPressed: () => _update(const ProductFilter(sort: ProductSort.newest)),
                  child: const Text('Reset'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            children: [
              if (widget.originalCategoryId != null &&
                  widget.originalCategoryId != _draft.categoryId)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.s,
                  ),
                  child: Text(
                    'Filtering within: ${widget.originalCategoryTitle ?? 'category'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              _section(
                title: 'Product type',
                hasSelection: _draft.type != null,
                onClear: () => _update(_draft.copyWith(type: null)),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in widget.options.productTypes)
                      ChoiceChip(
                        label: Text(t),
                        selected: _draft.type == t,
                        onSelected: (sel) =>
                            _update(_draft.copyWith(type: sel ? t : null)),
                      ),
                  ],
                ),
              ),
              _section(
                title: 'Routine step',
                hasSelection: _draft.step != null,
                onClear: () => _update(_draft.copyWith(step: null)),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in widget.options.routineSteps)
                      ChoiceChip(
                        label: Text(s.label),
                        selected: _draft.step == s.id,
                        onSelected: (sel) =>
                            _update(_draft.copyWith(step: sel ? s.id : null)),
                      ),
                    if (widget.options.routineSteps.isEmpty)
                      for (var i = 1; i <= 6; i++)
                        ChoiceChip(
                          label: Text(_routineLabel(i)),
                          selected: _draft.step == i,
                          onSelected: (sel) =>
                              _update(_draft.copyWith(step: sel ? i : null)),
                        ),
                  ],
                ),
              ),
              _section(
                title: 'Brand',
                hasSelection: _draft.brandIds.isNotEmpty,
                onClear: () => _update(_draft.copyWith(brandIds: const [])),
                child: Column(
                  children: [
                    for (final b in widget.options.brands)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(b.label),
                        value: _draft.brandIds.contains(b.id),
                        onChanged: (sel) {
                          final next = [..._draft.brandIds];
                          if (sel == true) {
                            if (!next.contains(b.id)) next.add(b.id);
                          } else {
                            next.remove(b.id);
                          }
                          _update(_draft.copyWith(brandIds: next));
                        },
                      ),
                  ],
                ),
              ),
              if (widget.options.skinTypes.isNotEmpty)
                _section(
                  title: 'Skin type',
                  hasSelection: _draft.skinTypeIds.isNotEmpty,
                  onClear: () => _update(_draft.copyWith(skinTypeIds: const [])),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in widget.options.skinTypes)
                        FilterChip(
                          label: Text(s.label),
                          selected: _draft.skinTypeIds.contains(s.id),
                          onSelected: (sel) {
                            final next = [..._draft.skinTypeIds];
                            if (sel) {
                              if (!next.contains(s.id)) next.add(s.id);
                            } else {
                              next.remove(s.id);
                            }
                            _update(_draft.copyWith(skinTypeIds: next));
                          },
                        ),
                    ],
                  ),
                ),
              if (widget.options.concerns.isNotEmpty)
                _section(
                  title: 'Skin concern',
                  hasSelection: _draft.concernIds.isNotEmpty,
                  onClear: () => _update(_draft.copyWith(concernIds: const [])),
                  child: Column(
                    children: [
                      for (final c in widget.options.concerns)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.label),
                          value: _draft.concernIds.contains(c.id),
                          onChanged: (sel) {
                            final next = [..._draft.concernIds];
                            if (sel == true) {
                              if (!next.contains(c.id)) next.add(c.id);
                            } else {
                              next.remove(c.id);
                            }
                            _update(_draft.copyWith(concernIds: next));
                          },
                        ),
                    ],
                  ),
                ),
              if (widget.options.ingredients.isNotEmpty)
                _section(
                  title: 'Key ingredient',
                  hasSelection: _draft.ingredientIds.isNotEmpty,
                  onClear: () => _update(_draft.copyWith(ingredientIds: const [])),
                  child: Column(
                    children: [
                      TextField(
                        controller: _ingredientSearch,
                        decoration: const InputDecoration(
                          hintText: 'Search ingredients',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      for (final i in widget.options.ingredients.where((i) =>
                          _ingredientSearch.text.isEmpty ||
                          i.label
                              .toLowerCase()
                              .contains(_ingredientSearch.text.toLowerCase())))
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(i.label),
                          value: _draft.ingredientIds.contains(i.id),
                          onChanged: (sel) {
                            final next = [..._draft.ingredientIds];
                            if (sel == true) {
                              if (!next.contains(i.id)) next.add(i.id);
                            } else {
                              next.remove(i.id);
                            }
                            _update(_draft.copyWith(ingredientIds: next));
                          },
                        ),
                    ],
                  ),
                ),
              if (widget.options.claims.isNotEmpty)
                _section(
                  title: 'Claims',
                  hasSelection: _draft.claimKeys.isNotEmpty,
                  onClear: () => _update(_draft.copyWith(claimKeys: const [])),
                  child: Column(
                    children: [
                      for (final c in widget.options.claims)
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(c.label),
                          value: _draft.claimKeys.contains(c.key),
                          onChanged: (sel) {
                            final next = [..._draft.claimKeys];
                            if (sel) {
                              if (!next.contains(c.key)) next.add(c.key);
                            } else {
                              next.remove(c.key);
                            }
                            _update(_draft.copyWith(claimKeys: next));
                          },
                        ),
                    ],
                  ),
                ),
              _section(
                title: 'Price range',
                hasSelection: _draft.minPrice != null || _draft.maxPrice != null,
                onClear: () =>
                    _update(_draft.copyWith(minPrice: null, maxPrice: null)),
                child: _PriceRangeEditor(
                  min: widget.options.minPrice ?? 0,
                  max: widget.options.maxPrice ?? 500,
                  value: RangeValues(
                    _draft.minPrice ?? widget.options.minPrice ?? 0,
                    _draft.maxPrice ?? widget.options.maxPrice ?? 500,
                  ),
                  onChanged: (r) => _update(
                    _draft.copyWith(minPrice: r.start, maxPrice: r.end),
                  ),
                ),
              ),
              _section(
                title: 'Quick toggles',
                hasSelection: _draft.spfOnly || _draft.inStockOnly || _draft.onSaleOnly,
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('SPF products only'),
                      value: _draft.spfOnly,
                      onChanged: (v) => _update(_draft.copyWith(spfOnly: v)),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('In stock only'),
                      value: _draft.inStockOnly,
                      onChanged: (v) => _update(_draft.copyWith(inStockOnly: v)),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('On sale only'),
                      value: _draft.onSaleOnly,
                      onChanged: (v) => _update(_draft.copyWith(onSaleOnly: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.screen),
            ],
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _update(const ProductFilter(sort: ProductSort.newest));
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: Text('Apply (${_draft.activeCount})'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    required bool hasSelection,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s,
        AppSpacing.screen,
        AppSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasSelection && onClear != null)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _routineLabel(int step) {
    const labels = {
      1: 'Cleanse',
      2: 'Tone',
      3: 'Treat',
      4: 'Moisturize',
      5: 'Protect',
      6: 'Weekly Treatment',
    };
    return labels[step] ?? 'Step $step';
  }
}

class _PriceRangeEditor extends StatefulWidget {
  final double min;
  final double max;
  final RangeValues value;
  final ValueChanged<RangeValues> onChanged;

  const _PriceRangeEditor({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_PriceRangeEditor> createState() => _PriceRangeEditorState();
}

class _PriceRangeEditorState extends State<_PriceRangeEditor> {
  late RangeValues _local = widget.value;

  @override
  void didUpdateWidget(covariant _PriceRangeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _local = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RangeSlider(
          values: _local,
          min: widget.min,
          max: widget.max == widget.min ? widget.min + 1 : widget.max,
          divisions: 50,
          labels: RangeLabels(
            formatPrice(_local.start),
            formatPrice(_local.end),
          ),
          onChanged: (r) {
            setState(() => _local = r);
            widget.onChanged(r);
          },
        ),
        Text(
          '${formatPrice(_local.start)} – ${formatPrice(_local.end)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}