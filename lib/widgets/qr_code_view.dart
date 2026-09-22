// lib/widgets/qr_code_view.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class QrCodeView extends StatelessWidget {
  const QrCodeView({super.key, required this.imageProvider});
  final ImageProvider imageProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Image(image: imageProvider, filterQuality: FilterQuality.none),
    );
  }
}