import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/image_url.dart';
import '../../models/product_category.dart';
import '../../models/product_filter.dart';
import '../../products/product_repository.dart';
import '../../widgets/state_views.dart';
import 'product_list_screen.dart';

enum _CatStatus { loading, error, ready }

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final ProductRepository _repo;
  _CatStatus _status = _CatStatus.loading;
  List<ProductCategory> _roots = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(AuthScope.of(context, listen: false).api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _status = _CatStatus.loading);
    try {
      final tree = await _repo.fetchCategoryTree();
      if (!mounted) return;
      setState(() {
        _roots = tree;
        _status = _CatStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _CatStatus.error;
        _error = 'Could not load categories.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: _body(),
    );
  }

  Widget _body() {
    switch (_status) {
      case _CatStatus.loading:
        return const LoadingIndicator();
      case _CatStatus.error:
        return ErrorStateView(message: _error ?? 'Error', onRetry: _load);
      case _CatStatus.ready:
        if (_roots.isEmpty) {
          return const EmptyState(
            icon: Icons.category_outlined,
            title: 'No categories',
            message: 'Categories will appear here once they are added.',
          );
        }
        final totalProducts = _roots.fold<int>(0, (a, b) => a + b.totalProductCount);
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(
                'Browse categories',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalProducts products',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.m),
              for (final root in _roots) _CategoryTile(node: root),
              const SizedBox(height: AppSpacing.screen),
            ],
          ),
        );
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final ProductCategory node;
  const _CategoryTile({required this.node});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: AppSpacing.l),
        leading: _thumb(),
        title: Text(
          node.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${node.totalProductCount} products'),
        onExpansionChanged: (_) {},
        children: [
          if (node.children.isEmpty)
            ListTile(
              dense: true,
              title: const Text('All products'),
              onTap: () => _open(context, node),
            )
          else
            for (final child in node.children) _childTile(context, child),
          const Divider(height: 1),
          ListTile(
            dense: true,
            title: const Text('All products in this category'),
            onTap: () => _open(context, node),
          ),
        ],
      ),
    );
  }

  Widget _childTile(BuildContext context, ProductCategory child) {
    if (child.children.isEmpty) {
      return ListTile(
        dense: true,
        title: Text(child.name),
        subtitle: Text('${child.totalProductCount} products'),
        onTap: () => _open(context, child),
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(child.name),
        subtitle: Text('${child.totalProductCount} products'),
        children: [
          for (final grand in child.children)
            ListTile(
              dense: true,
              title: Text(grand.name),
              subtitle: Text('${grand.totalProductCount} products'),
              onTap: () => _open(context, grand),
            ),
        ],
      ),
    );
  }

  Widget _thumb() {
    final url = resolveImageUrl(node.image);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: SizedBox(
        width: 44,
        height: 44,
        child: url == null
            ? Container(
                color: AppColors.surfaceMuted,
                child: const Icon(Icons.category_outlined),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceMuted,
                  child: const Icon(Icons.category_outlined),
                ),
              ),
      ),
    );
  }

  void _open(BuildContext context, ProductCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          initialFilter: ProductFilter(categoryId: category.categoryId),
          title: category.name,
        ),
      ),
    );
  }
}