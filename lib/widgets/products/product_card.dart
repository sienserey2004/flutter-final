import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/product.dart';
import 'price_text.dart';
import 'product_badge.dart';
import 'product_image_tile.dart';
import 'product_rating_stars.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onToggleWishlist;
  final bool? isWishlisted;
  final bool compact;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onToggleWishlist,
    this.isWishlisted,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final heart = onToggleWishlist == null
        ? null
        : Positioned(
            top: 4,
            right: 4,
            child: SizedBox(
              width: kMinTouchTarget,
              height: kMinTouchTarget,
              child: Center(
                child: Material(
                  color: AppColors.surface.withOpacity(0.85),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onToggleWishlist,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        (isWishlisted ?? false)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: (isWishlisted ?? false)
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

    final badges = <Widget>[
      if (product.isOutOfStock)
        const ProductBadge(label: 'Out of stock', kind: ProductBadgeKind.outOfStock)
      else if ((product.discountPercent ?? 0) > 0)
        ProductBadge(
          label: 'Sale −${product.discountPercent}%',
          kind: ProductBadgeKind.sale,
        )
      else if (product.claims.contains('new'))
        const ProductBadge(label: 'New', kind: ProductBadgeKind.isNew),
    ];

    final image = Stack(
      fit: StackFit.expand,
      children: [
        ProductImageTile(
          url: product.primaryImage,
          semanticLabel: product.name,
        ),
        if (badges.isNotEmpty)
          Positioned(top: 8, left: 8, child: Column(children: badges)),
        if (heart != null) heart,
      ],
    );

    // Reserve a fixed number of lines so cards in the same row line up
    // whether the name wraps or not.
    final textScaler = MediaQuery.textScalerOf(context);
    final nameHeight = textScaler.scale(14) * 1.2 * 2;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          (product.brand ?? '').toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: nameHeight),
          child: Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 2),
          Text(
            product.concerns.take(2).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ProductRatingStars(
            rating: product.avgRating,
            reviewCount: product.reviewCount,
          ),
        ],
        const SizedBox(height: 6),
        PriceText(
          price: product.basePrice,
          compareAtPrice: product.compareAtPrice,
          discountPercent: product.discountPercent,
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // In a grid or fixed-height list the image takes whatever height is
          // left after the text, so the card can never overflow. In an
          // unbounded parent (list rows) it stays square.
          if (constraints.hasBoundedHeight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: image), details],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [AspectRatio(aspectRatio: 1, child: image), details],
          );
        },
      ),
    );
  }
}

/// Small compact row used inside search suggestions.
class ProductSuggestionRow extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductSuggestionRow({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: ProductImageTile(url: product.primaryImage, semanticLabel: product.name),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand != null)
                    Text(
                      product.brand!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PriceText(price: product.basePrice, size: 13),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}