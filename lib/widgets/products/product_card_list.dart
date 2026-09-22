import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/product.dart';
import 'product_card.dart';
import 'section_header.dart';

class ProductCardList extends StatelessWidget {
  final String title;
  final List<Product> products;
  final VoidCallback? onSeeAll;
  final void Function(Product) onTapProduct;
  final void Function(Product)? onToggleWishlist;
  final Set<int> wishlistedIds;

  const ProductCardList({
    super.key,
    required this.title,
    required this.products,
    required this.onTapProduct,
    this.onSeeAll,
    this.onToggleWishlist,
    this.wishlistedIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onSeeAll: onSeeAll),
        SizedBox(
          height: 260,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.m),
            itemBuilder: (context, i) {
              final p = products[i];
              return SizedBox(
                width: 150,
                child: ProductCard(
                  product: p,
                  onTap: () => onTapProduct(p),
                  onToggleWishlist: onToggleWishlist == null
                      ? null
                      : () => onToggleWishlist!(p),
                  isWishlisted: wishlistedIds.contains(p.productId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}