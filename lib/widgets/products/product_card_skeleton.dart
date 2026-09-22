import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class ProductCardSkeleton extends StatelessWidget {
  final double? width;
  const ProductCardSkeleton({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1, child: _block()),
          const SizedBox(height: 8),
          _block(height: 10, widthFactor: 0.4),
          const SizedBox(height: 6),
          _block(height: 12, widthFactor: 0.9),
          const SizedBox(height: 6),
          _block(height: 12, widthFactor: 0.6),
        ],
      ),
    );
  }

  Widget _block({double? height, double widthFactor = 1}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height ?? 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
      ),
    );
  }
}