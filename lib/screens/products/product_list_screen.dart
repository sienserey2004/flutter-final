import 'package:flutter/material.dart';
import '../../auth/auth_controller.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/session_actions.dart';
import '../../models/filter_options.dart';
import '../../models/product.dart';
import '../../models/product_filter.dart';
import '../../products/product_repository.dart';
import '../../widgets/products/filter_chip_row.dart';
import '../../widgets/products/price_text.dart';
import '../../widgets/products/product_card.dart';
import '../../widgets/products/product_card_skeleton.dart';
import '../../widgets/products/product_rating_stars.dart';
import '../../widgets/state_views.dart';
import 'filter_sheet.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'sort_sheet.dart';

enum _ListStatus { loading, error, ready }

class ProductListScreen extends StatefulWidget {
  final ProductFilter initialFilter;
  final String? title;

  const ProductListScreen({
    super.key,
    this.initialFilter = const ProductFilter(),
    this.title,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ProductFilter _filter;
  late final ProductRepository _repo;
  late final ScrollController _scroll;

  _ListStatus _status = _ListStatus.loading;
  String? _error;
  final List<Product> _items = [];
  final Set<int> _wishlisted = {};
  int _page = 1;
  int _pages = 1;
  int _total = 0;
  bool _loadingMore = false;
  bool _grid = true;
  FilterOptions _options = FilterOptions.empty;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _repo = ProductRepository(AuthScope.of(context, listen: false).api);
    _scroll = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 400 && !_loadingMore && _page < _pages) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _status = _ListStatus.loading;
      _error = null;
      _items.clear();
      _page = 1;
      _pages = 1;
    });
    try {
      final result = await _repo.fetchProducts(_filter, page: 1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(result.products);
        _page = result.page;
        _pages = result.pages;
        _total = result.total;
        _options = result.options;
        _status = _ListStatus.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _status = _ListStatus.error;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _pages) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _repo.fetchProducts(_filter, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.products);
        _page = result.page;
        _pages = result.pages;
        _total = result.total;
      });
    } catch (_) {
      // Silent failure for pagination — the user can pull to retry.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openFilter() async {
    final next = await FilterSheet.show(
      context,
      current: _filter,
      options: _options,
      originalCategoryId: widget.initialFilter.categoryId,
      originalCategoryTitle: widget.title,
    );
    if (next == null) return;
    setState(() {
      // Preserve q from route so a category drill-down keeps search scope.
      _filter = next.copyWith(q: widget.initialFilter.q);
    });
    await _load();
  }

  Future<void> _openSort() async {
    final picked = await SortSheet.show(
      context,
      current: _filter.sort,
      options: _options,
    );
    if (picked == null || picked == _filter.sort) return;
    setState(() => _filter = _filter.copyWith(sort: picked));
    await _load();
  }

  Future<void> _toggleWishlist(Product p) async {
    if (!await requireLogin(context) || !mounted) return;
    final wasWishlisted = _wishlisted.contains(p.productId);
    setState(() {
      if (wasWishlisted) {
        _wishlisted.remove(p.productId);
      } else {
        _wishlisted.add(p.productId);
      }
    });
    try {
      final result = await _repo.toggleWishlist(p.productId);
      if (!mounted) return;
      setState(() {
        if (result.inWishlist) {
          _wishlisted.add(p.productId);
        } else {
          _wishlisted.remove(p.productId);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasWishlisted) {
          _wishlisted.add(p.productId);
        } else {
          _wishlisted.remove(p.productId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorites')),
      );
    }
  }

  void _openDetail(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: p.productId),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialQuery: _filter.q),
      ),
    );
  }

  void _removeChip(ProductFilter next) {
    setState(() => _filter = next);
    _load();
  }

  List<RemovableChip> _buildChips() {
    final chips = <RemovableChip>[];
    void add(String label, ProductFilter Function() make) {
      chips.add(RemovableChip(label: label, onRemove: () => _removeChip(make())));
    }

    if (_filter.categoryId != null && widget.initialFilter.categoryId == null) {
      add('Category', () => _filter.copyWith(categoryId: null));
    }
    if (_filter.type != null) add(_filter.type!, () => _filter.copyWith(type: null));
    if (_filter.step != null) add('Step ${_filter.step}', () => _filter.copyWith(step: null));
    if (_filter.brandIds.isNotEmpty) {
      add('${_filter.brandIds.length} brand(s)',
          () => _filter.copyWith(brandIds: const []));
    }
    if (_filter.skinTypeIds.isNotEmpty) {
      add('${_filter.skinTypeIds.length} skin type(s)',
          () => _filter.copyWith(skinTypeIds: const []));
    }
    if (_filter.concernIds.isNotEmpty) {
      add('${_filter.concernIds.length} concern(s)',
          () => _filter.copyWith(concernIds: const []));
    }
    if (_filter.ingredientIds.isNotEmpty) {
      add('${_filter.ingredientIds.length} ingredient(s)',
          () => _filter.copyWith(ingredientIds: const []));
    }
    if (_filter.claimKeys.isNotEmpty) {
      add('${_filter.claimKeys.length} claim(s)',
          () => _filter.copyWith(claimKeys: const []));
    }
    if (_filter.minPrice != null || _filter.maxPrice != null) {
      add('Price', () => _filter.copyWith(minPrice: null, maxPrice: null));
    }
    if (_filter.spfOnly) add('SPF only', () => _filter.copyWith(spfOnly: false));
    if (_filter.inStockOnly) add('In stock', () => _filter.copyWith(inStockOnly: false));
    if (_filter.onSaleOnly) add('On sale', () => _filter.copyWith(onSaleOnly: false));
    return chips;
  }

  String get _appBarTitle {
    if (widget.title != null && widget.title!.isNotEmpty) return widget.title!;
    final q = widget.initialFilter.q;
    if (q != null && q.isNotEmpty) return 'Search: "$q"';
    return 'All products';
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('session')) return 'Your session has expired. Please log in again.';
    return 'Could not load products. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_appBarTitle),
            if (_status == _ListStatus.ready)
              Text(
                '$_total result${_total == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          _controlsRow(),
          if (_buildChips().isNotEmpty)
            FilterChipRow(
              chips: _buildChips(),
              onClearAll: () {
                setState(() {
                  _filter = ProductFilter(
                    q: widget.initialFilter.q,
                    sort: _filter.sort,
                  );
                });
                _load();
              },
            ),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _controlsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s,
        AppSpacing.screen,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _openFilter,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Row(
              children: [
                const Text('Filter'),
                if (_filter.activeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.s),
                    ),
                    child: Text(
                      '${_filter.activeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          OutlinedButton.icon(
            onPressed: _openSort,
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label: Text(_sortLabel()),
          ),
          const Spacer(),
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _grid = !_grid),
          ),
        ],
      ),
    );
  }

  String _sortLabel() {
    final label = _options.sorts[_filter.sort.queryValue];
    return label ?? _filter.sort.label;
  }

  Widget _body() {
    switch (_status) {
      case _ListStatus.loading:
        return const LoadingIndicator();
      case _ListStatus.error:
        return ErrorStateView(message: _error ?? 'Error', onRetry: _load);
      case _ListStatus.ready:
        if (_items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No products found',
                  message: 'Try a different search term or filter.',
                  action: TextButton(
                    onPressed: () {
                      setState(() => _filter = ProductFilter(sort: _filter.sort));
                      _load();
                    },
                    child: const Text('Clear filters'),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: _grid ? _buildGrid() : _buildList(),
        );
    }
  }

  Widget _buildGrid() {
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: AppSpacing.m,
              crossAxisSpacing: AppSpacing.m,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => ProductCard(
                product: _items[i],
                onTap: () => _openDetail(_items[i]),
                onToggleWishlist: () => _toggleWishlist(_items[i]),
                isWishlisted: _wishlisted.contains(_items[i].productId),
              ),
              childCount: _items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _footer()),
      ],
    );
  }

  Widget _buildList() {
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: _items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.l),
      itemBuilder: (context, i) {
        if (i == _items.length) return _footer();
        final p = _items[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: ProductCard(
                product: p,
                compact: true,
                onTap: () => _openDetail(p),
                onToggleWishlist: () => _toggleWishlist(p),
                isWishlisted: _wishlisted.contains(p.productId),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.brand != null)
                      Text(
                        p.brand!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (p.concerns.isNotEmpty)
                      Text(
                        p.concerns.take(3).join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    ProductRatingStars(
                      rating: p.avgRating,
                      reviewCount: p.reviewCount,
                    ),
                    const SizedBox(height: 8),
                    PriceText(
                      price: p.basePrice,
                      compareAtPrice: p.compareAtPrice,
                      discountPercent: p.discountPercent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _footer() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.screen);
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}