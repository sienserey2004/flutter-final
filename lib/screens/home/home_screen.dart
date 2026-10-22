// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/product.dart';
import '../../models/product_filter.dart';
import '../../products/home_repository.dart';
import '../../products/product_repository.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/products/product_card_list.dart';
import '../../widgets/state_views.dart';
import '../../widgets/wishlist_button.dart';
import '../products/categories_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/product_list_screen.dart';
import '../products/recommended_screen.dart';
import '../products/search_screen.dart';

enum _HomeStatus { loading, error, ready }

const Map<int, String> kRoutineSteps = {
  1: 'Cleanse',
  2: 'Tone',
  3: 'Treat',
  4: 'Moisturize',
  5: 'Protect',
  6: 'Weekly Treatment',
};

class HomeScreen extends StatefulWidget {
  final void Function(int index) onNavigateToTab;
  final int unreadNotifications;

  const HomeScreen({
    super.key,
    required this.onNavigateToTab,
    this.unreadNotifications = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeRepository _homeRepo;
  late final ProductRepository _productRepo;
  _HomeStatus _status = _HomeStatus.loading;
  HomePayload _payload = const HomePayload();
  List<Product> _recommended = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    final scope = AuthScope.of(context, listen: false);
    _homeRepo = HomeRepository(scope.api);
    _productRepo = ProductRepository(scope.api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _status = _HomeStatus.loading);
    try {
      final payload = await _homeRepo.fetchHome();
      List<Product> recommended = payload.bestsellers;
      final scope = AuthScope.of(context, listen: false);
      if (scope.user != null) {
        try {
          final rec = await _productRepo.fetchForYou();
          if (rec.products.isNotEmpty) recommended = rec.products;
        } catch (_) {
          // Silent fallback to bestsellers.
        }
      }
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _recommended = recommended;
        _status = _HomeStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _HomeStatus.error;
        _error = 'Could not load the storefront.';
      });
    }
  }

  void _openDetail(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.productId)),
    );
  }

  void _openList(ProductListScreen screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    switch (_status) {
      case _HomeStatus.loading:
        return const LoadingIndicator();
      case _HomeStatus.error:
        return ErrorStateView(message: _error ?? 'Error', onRetry: _load);
      case _HomeStatus.ready:
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _header(),
              _searchBar(),
              _promoBanner(),
              _categoriesRow(),
              _routineRow(),
              if (_payload.newIn.isNotEmpty)
                ProductCardList(
                  title: 'New in',
                  products: _payload.newIn,
                  onTapProduct: _openDetail,
                  onSeeAll: () => _openList(
                    const ProductListScreen(
                      initialFilter: ProductFilter(sort: ProductSort.newest),
                      title: 'New in',
                    ),
                  ),
                ),
              if (_payload.bestsellers.isNotEmpty)
                ProductCardList(
                  title: 'Best sellers',
                  products: _payload.bestsellers,
                  onTapProduct: _openDetail,
                  onSeeAll: () => _openList(
                    const ProductListScreen(
                      initialFilter: ProductFilter(sort: ProductSort.rating),
                      title: 'Best sellers',
                    ),
                  ),
                ),
              if (_payload.onSale.isNotEmpty)
                ProductCardList(
                  title: 'On sale',
                  products: _payload.onSale,
                  onTapProduct: _openDetail,
                  onSeeAll: () => _openList(
                    const ProductListScreen(
                      initialFilter: ProductFilter(onSaleOnly: true),
                      title: 'On sale',
                    ),
                  ),
                ),
              if (_recommended.isNotEmpty)
                ProductCardList(
                  title: 'Recommended for you',
                  products: _recommended,
                  onTapProduct: _openDetail,
                  onSeeAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecommendedScreen()),
                  ),
                ),
              if (_payload.concerns.isNotEmpty) _concernsRow(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.l,
                ),
                child: OutlinedButton(
                  onPressed: () => _openList(
                    const ProductListScreen(title: 'All products'),
                  ),
                  child: const Text('Browse all products'),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.m,
        AppSpacing.screen,
        AppSpacing.s,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Aurea Skin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () => widget.onNavigateToTab(2),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (widget.unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.unreadNotifications}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const WishlistButton(),
          const CartButton(),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.s,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text(
                'Search products',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promoBanner() {
    final promos = _payload.activePromos;
    final promo = promos.isNotEmpty ? promos.first : null;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.s,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo?.title ?? 'Glow all season',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promo?.description ?? 'Clean formulas, real results.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (promo?.endsAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ends ${formatDate(promo!.endsAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            FilledButton(
              onPressed: () => _openList(
                const ProductListScreen(title: 'Shop sale'),
              ),
              child: Text(promo?.cta ?? 'Shop sale'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoriesRow() {
    if (_payload.categories.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.l,
            AppSpacing.screen,
            AppSpacing.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Shop by category',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            scrollDirection: Axis.horizontal,
            itemCount: _payload.categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.m),
            itemBuilder: (context, i) {
              if (i == _payload.categories.length) {
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  ),
                  child: const SizedBox(
                    width: 84,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.surfaceMuted,
                          child: Icon(Icons.apps_rounded),
                        ),
                        SizedBox(height: 6),
                        Text('All categories', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }
              final c = _payload.categories[i];
              return InkWell(
                onTap: () => _openList(
                  ProductListScreen(
                    initialFilter: ProductFilter(categoryId: c.categoryId),
                    title: c.name,
                  ),
                ),
                child: SizedBox(
                  width: 84,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.surfaceMuted,
                        child: const Icon(Icons.category_outlined),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        '${c.totalProductCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _routineRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.l,
            AppSpacing.screen,
            AppSpacing.s,
          ),
          child: Text(
            'Shop by routine step',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            scrollDirection: Axis.horizontal,
            itemCount: kRoutineSteps.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final entry = kRoutineSteps.entries.elementAt(i);
              return ActionChip(
                label: Text(entry.value),
                onPressed: () => _openList(
                  ProductListScreen(
                    initialFilter: ProductFilter(step: entry.key),
                    title: entry.value,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _concernsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.l,
            AppSpacing.screen,
            AppSpacing.s,
          ),
          child: Text(
            'Shop by concern',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _payload.concerns)
                ActionChip(
                  label: Text(c.name),
                  onPressed: () => _openList(
                    ProductListScreen(
                      initialFilter: ProductFilter(concernIds: [c.id]),
                      title: c.name,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}