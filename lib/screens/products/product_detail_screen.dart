import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../core/session_actions.dart';
import '../../models/product.dart';
import '../../models/product_detail.dart';
import '../../products/product_repository.dart';
import '../../shopping/cart_scope.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/products/price_text.dart';
import '../../widgets/products/product_card_list.dart';
import '../../widgets/products/product_image_tile.dart';
import '../../widgets/products/product_rating_stars.dart';
import '../../widgets/products/review_form_sheet.dart';
import '../../widgets/products/star_histogram_row.dart';
import '../../widgets/state_views.dart';
import '../shopping/cart_screen.dart';

enum _DetailStatus { loading, error, ready }

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductRepository _repo;
  _DetailStatus _status = _DetailStatus.loading;
  ProductDetail? _detail;
  ProductVariant? _selectedVariant;
  bool _wishlisted = false;
  String? _error;
  bool _descExpanded = false;
  bool _ingredientsExpanded = false;
  int _reviewLimit = 3;

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(AuthScope.of(context, listen: false).api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _status = _DetailStatus.loading;
      _error = null;
    });
    try {
      final detail = await _repo.fetchProductDetail(widget.productId);
      if (!mounted) return;
      final defaultVariant = detail.variants.firstWhere(
        (v) => !v.isOutOfStock,
        orElse: () => detail.variants.isNotEmpty
            ? detail.variants.first
            : const ProductVariant(price: 0, label: ''),
      );
      setState(() {
        _detail = detail;
        _selectedVariant = detail.variants.isEmpty ? null : defaultVariant;
        _wishlisted = detail.inWishlist;
        _status = _DetailStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _DetailStatus.error;
        _error = 'Could not load this product.';
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (!AuthScope.of(context, listen: false).isAuthenticated) {
      if (!await requireLogin(context) || !mounted) return;
      await _load();
      if (!mounted || _wishlisted) return;
    }
    final before = _wishlisted;
    setState(() => _wishlisted = !_wishlisted);
    try {
      final r = await _repo.toggleWishlist(widget.productId);
      if (!mounted) return;
      setState(() => _wishlisted = r.inWishlist);
    } catch (_) {
      if (!mounted) return;
      setState(() => _wishlisted = before);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorites')),
      );
    }
  }

  Future<void> _writeReview() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await requireLogin(context) || !mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => ReviewFormSheet(
        repository: _repo,
        productId: widget.productId,
        productName: _detail!.product.name,
      ),
    );
    if (saved != true || !mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Thanks! Your review was saved.')),
    );
    await _load();
  }

  Future<void> _addToCart() async {
    final variantId = _selectedVariant?.variantId;
    final messenger = ScaffoldMessenger.of(context);
    if (variantId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please choose an option first')),
      );
      return;
    }
    if (!await requireLogin(context) || !mounted) return;
    final cart = CartScope.of(context, listen: false);
    final ok = await cart.add(variantId: variantId);
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Added "${_detail!.product.name}" to cart'
            : cart.errorMessage ?? 'Could not add to cart'),
        action: ok
            ? SnackBarAction(
                label: 'View cart',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              )
            : null,
      ),
    );
  }

  void _openDetail(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.productId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
      bottomNavigationBar: _status == _DetailStatus.ready ? _bottomBar() : null,
    );
  }

  Widget _body() {
    switch (_status) {
      case _DetailStatus.loading:
        return const LoadingIndicator();
      case _DetailStatus.error:
        return Scaffold(
          appBar: AppBar(),
          body: ErrorStateView(message: _error ?? 'Error', onRetry: _load),
        );
      case _DetailStatus.ready:
        final d = _detail!;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                d.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  onPressed: _toggleWishlist,
                  icon: Icon(
                    _wishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _wishlisted ? AppColors.danger : null,
                  ),
                ),
                const CartButton(),
              ],
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 320,
                child: _gallery(d.product),
              ),
            ),
            SliverToBoxAdapter(child: _content(d)),
          ],
        );
    }
  }

  Widget _gallery(Product p) {
    final urls = p.images.isNotEmpty
        ? p.images
        : [if (p.image != null) p.image!];
    if (urls.isEmpty) {
      return Container(color: AppColors.surfaceMuted);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: urls.length,
          itemBuilder: (_, i) => ProductImageTile(
            url: urls[i],
            fit: BoxFit.cover,
            borderRadius: BorderRadius.zero,
            semanticLabel: p.name,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppRadius.l),
              ),
              child: Text(
                '${urls.length} image${urls.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(ProductDetail d) {
    final p = d.product;
    final variant = _selectedVariant;
    final price = variant?.price ?? p.basePrice;
    final compare = variant?.compareAtPrice ?? p.compareAtPrice;
    final discount = variant?.discountPercent ?? p.discountPercent;
    final totalReviews = p.reviewCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.m,
        AppSpacing.screen,
        AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!p.isActive)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: const Text('This product is no longer available'),
            ),
          if (p.brand != null)
            Text(
              '${p.brand}${p.category != null ? ' · ${p.category}' : ''}',
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            p.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              ProductRatingStars(rating: p.avgRating),
              const SizedBox(width: 8),
              Text(
                '${p.avgRating.toStringAsFixed(1)} · $totalReviews reviews',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          PriceText(
            price: price,
            compareAtPrice: compare,
            discountPercent: discount,
            size: 22,
          ),
          const SizedBox(height: AppSpacing.m),
          if (d.variants.isNotEmpty) ...[
            const Text('Options', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in d.variants)
                  ChoiceChip(
                    label: Text(v.label),
                    selected: _selectedVariant?.variantId == v.variantId &&
                        _selectedVariant?.label == v.label,
                    onSelected: v.isOutOfStock
                        ? null
                        : (_) => setState(() => _selectedVariant = v),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          if (p.description != null && p.description!.isNotEmpty) ...[
            Text(
              p.description!,
              maxLines: _descExpanded ? null : 3,
              overflow: _descExpanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(height: 1.5, color: AppColors.textPrimary),
            ),
            if (p.description!.length > 120)
              TextButton(
                onPressed: () => setState(() => _descExpanded = !_descExpanded),
                child: Text(_descExpanded ? 'Read less' : 'Read more'),
              ),
            const SizedBox(height: AppSpacing.s),
          ],
          _detailsGrid(p),
          if (p.claims.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in p.claims)
                  Chip(label: Text(c.replaceAll('_', ' '))),
              ],
            ),
          ],
          if (d.ingredients.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            const Text(
              'Key ingredients',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final i in d.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(i.displayName)),
                  ],
                ),
              ),
          ],
          if (p.skinTypes.isNotEmpty || p.concerns.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            const Text(
              'Suits',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in p.skinTypes) Chip(label: Text(s)),
                for (final c in p.concerns) Chip(label: Text(c)),
              ],
            ),
          ],
          if (d.howToUse != null && d.howToUse!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            const Text(
              'How to use',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(d.howToUse!, style: const TextStyle(height: 1.5)),
          ],
          if (d.ingredientsFull != null && d.ingredientsFull!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            InkWell(
              onTap: () => setState(() => _ingredientsExpanded = !_ingredientsExpanded),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Full ingredients',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(_ingredientsExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded),
                ],
              ),
            ),
            if (_ingredientsExpanded) ...[
              const SizedBox(height: 8),
              Text(d.ingredientsFull!, style: const TextStyle(height: 1.5)),
            ],
          ],
          const SizedBox(height: AppSpacing.l),
          _reviewsSection(d),
          if (d.routine.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            ProductCardList(
              title: 'Completes your routine',
              products: d.routine,
              onTapProduct: _openDetail,
            ),
          ],
          if (d.related.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            ProductCardList(
              title: 'You may also like',
              products: d.related,
              onTapProduct: _openDetail,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsGrid(Product p) {
    final rows = <MapEntry<String, String>>[];
    if (p.productType != null) rows.add(MapEntry('Type', p.productType!));
    if (p.texture != null) rows.add(MapEntry('Texture', p.texture!));
    if (p.volumeLabel != null) rows.add(MapEntry('Volume', p.volumeLabel!));
    if (p.spf != null) rows.add(MapEntry('SPF', '${p.spf}'));
    if (p.paoMonths != null) rows.add(MapEntry('PAO', '${p.paoMonths} months'));
    if (p.routineStepLabel != null) rows.add(MapEntry('Routine step', p.routineStepLabel!));
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      r.key,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _reviewsSection(ProductDetail d) {
    final total = d.reviews.length;
    final totalForHistogram = d.ratingBreakdown.values.fold<int>(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Reviews',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _writeReview,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Write a review'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              d.product.avgRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                children: [
                  for (var star = 5; star >= 1; star--)
                    StarHistogramRow(
                      star: star,
                      count: d.ratingBreakdown[star] ?? 0,
                      total: totalForHistogram,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        if (d.reviews.isEmpty)
          const Text(
            'No reviews yet.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          for (final r in d.reviews.take(_reviewLimit))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        formatDate(r.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ProductRatingStars(rating: r.rating, size: 12),
                      if (r.skinType != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(r.skinType!),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ],
                  ),
                  if (r.title != null && r.title!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.title!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (r.comment != null) ...[
                    const SizedBox(height: 4),
                    Text(r.comment!, style: const TextStyle(height: 1.4)),
                  ],
                ],
              ),
            ),
        if (total > _reviewLimit)
          TextButton(
            onPressed: () => setState(() => _reviewLimit += 5),
            child: const Text('Load more reviews'),
          ),
      ],
    );
  }

  Widget _bottomBar() {
    final p = _detail!.product;
    final variant = _selectedVariant;
    final price = variant?.price ?? p.basePrice;
    final stock = variant?.stock ?? p.totalStock;
    final outOfStock = stock <= 0 || !p.isActive;
    final busy = CartScope.of(context).isBusy;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.screen),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  Text(
                    formatPrice(price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: outOfStock || busy ? null : _addToCart,
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(outOfStock ? 'Out of stock' : 'Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
