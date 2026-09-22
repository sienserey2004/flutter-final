import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../models/product_filter.dart';
import '../../products/product_repository.dart';
import '../../widgets/products/product_card.dart';
import '../../widgets/state_views.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';

const String _recentsKey = 'recent_product_searches';
const List<String> _popular = [
  'SPF 50',
  'Vitamin C',
  'Retinol',
  'Cleanser',
  'Sensitive skin',
];

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ProductRepository _repo;
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  List<Product> _results = const [];
  List<String> _recents = const [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(AuthScope.of(context, listen: false).api);
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _query = widget.initialQuery ?? '';
    _loadRecents();
    if (_query.isNotEmpty) {
      _runSearch(_query, debounce: false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_query.isEmpty) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recents = prefs.getStringList(_recentsKey) ?? const []);
  }

  Future<void> _persistRecent(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final next = [t, ...(_recents.where((e) => e != t))].take(10).toList();
    await prefs.setStringList(_recentsKey, next);
    if (!mounted) return;
    setState(() => _recents = next);
  }

  Future<void> _clearRecents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentsKey);
    if (!mounted) return;
    setState(() => _recents = const []);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value);
    if (value.trim().isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(value, debounce: false);
    });
  }

  Future<void> _runSearch(String rawTerm, {bool debounce = true}) async {
    final term = rawTerm.trim();
    if (term.isEmpty) return;
    if (debounce) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(term, debounce: false));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.fetchProducts(
        ProductFilter(q: term),
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _results = result.products;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not search right now.';
      });
    }
  }

  void _submit() {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    _debounce?.cancel();
    _persistRecent(term);
    _runSearch(term, debounce: false);
  }

  void _openListAll() {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    _persistRecent(term);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          initialFilter: ProductFilter(q: term),
          title: 'Search: "$term"',
        ),
      ),
    );
  }

  void _openDetail(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.productId)),
    );
  }

  void _fill(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _persistRecent(term);
    _runSearch(term, debounce: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Search products',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                  ),
            border: InputBorder.none,
          ),
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_query.trim().isEmpty) return _idle();
    if (_error != null) {
      return ErrorStateView(
        message: _error!,
        onRetry: () => _runSearch(_query, debounce: false),
      );
    }
    if (_loading && _results.isEmpty) {
      return const LoadingIndicator();
    }
    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No products match "$_query"',
        message: 'Try a different term or browse all products.',
        action: TextButton(
          onPressed: _openListAll,
          child: const Text('Show all'),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == _results.length) {
          return TextButton(
            onPressed: _openListAll,
            child: Text('Show all results for "$_query"'),
          );
        }
        return ProductSuggestionRow(
          product: _results[i],
          onTap: () => _openDetail(_results[i]),
        );
      },
    );
  }

  Widget _idle() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      children: [
        if (_recents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s,
              AppSpacing.screen,
              0,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent searches',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: _clearRecents,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _recents)
                  ActionChip(label: Text(r), onPressed: () => _fill(r)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
        ],
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 0),
          child: Text(
            'Popular searches',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _popular)
                ActionChip(label: Text(p), onPressed: () => _fill(p)),
            ],
          ),
        ),
      ],
    );
  }
}