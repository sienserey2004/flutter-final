import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/image_url.dart';

class ProductImageTile extends StatelessWidget {
  final String? url;
  final double? aspectRatio;
  final BoxFit fit;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  const ProductImageTile({
    super.key,
    required this.url,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.m);

    Widget content;
    if (resolved == null) {
      content = _placeholder();
    } else {
      content = Image.network(
        resolved,
        fit: fit,
        semanticLabel: semanticLabel,
        cacheWidth: 600,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(loading: true);
        },
        errorBuilder: (context, error, stack) => _placeholder(broken: true),
      );
    }

    final clipped = ClipRRect(borderRadius: radius, child: content);
    if (aspectRatio == null) return clipped;
    return AspectRatio(aspectRatio: aspectRatio!, child: clipped);
  }

  Widget _placeholder({bool loading = false, bool broken = false}) {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              broken
                  ? Icons.broken_image_outlined
                  : Icons.image_outlined,
              color: AppColors.textSecondary,
            ),
    );
  }
}