// lib/screens/products/recommended_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../products/product_repository.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/products/product_card_list.dart';
import '../../widgets/state_views.dart';
import 'product_detail_screen.dart';

enum _RecStatus { loading, error, ready }

class RecommendedScreen extends StatefulWidget {
  const RecommendedScreen({super.key});

  @override
  State<RecommendedScreen> createState() => _RecommendedScreenState();
}

class _RecommendedScreenState extends State<RecommendedScreen> {
  late final ProductRepository _repo;
  _RecStatus _status = _RecStatus.loading;
  RecommendedResult _result = const RecommendedResult();
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = ProductRepository(AuthScope.of(context, listen: false).api);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _status = _RecStatus.loading);
    try {
      final res = await _repo.fetchForYou();
      if (!mounted) return;
      setState(() {
        _result = res;
        _status = _RecStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _RecStatus.error;
        _error = 'Could not load recommendations.';
      });
    }
  }

  void _openDetail(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.productId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended for you'),
        actions: const [
          CartButton(),
          SizedBox(width: AppSpacing.s),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _RecStatus.loading:
        return const LoadingIndicator();
      case _RecStatus.error:
        return ErrorStateView(
          message: _error ?? 'Could not load recommendations.',
          onRetry: _load,
        );
      case _RecStatus.ready:
        final routine = _result.routine;
        final products = _result.products;
        final profile = _result.profile;

        if (routine.isEmpty && products.isEmpty) {
          return EmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'No recommendations yet',
            message: _result.message ??
                'Set up your skin profile or browse products to get personalized recommendations.',
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              if (profile != null) _profileCard(profile),
              if (routine.isNotEmpty) ...[
                for (final step in routine)
                  if (step.products.isNotEmpty)
                    ProductCardList(
                      title: step.label.isNotEmpty
                          ? step.label
                          : 'Step ${step.step}',
                      products: step.products,
                      onTapProduct: _openDetail,
                    ),
              ] else if (products.isNotEmpty) ...[
                ProductCardList(
                  title: 'Top picks for you',
                  products: products,
                  onTapProduct: _openDetail,
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _profileCard(Map<String, dynamic> profile) {
    final skinType = profile['skin_type'] as String? ?? '';
    final concerns = (profile['concerns'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return Container(
      margin: const EdgeInsets.all(AppSpacing.screen),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Personalized for your skin',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          if (skinType.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Skin Type: $skinType', style: const TextStyle(fontSize: 12)),
          ],
          if (concerns.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Concerns: ${concerns.join(", ")}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}