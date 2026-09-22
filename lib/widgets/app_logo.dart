// lib/widgets/app_logo.dart
import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 64,
    this.showText = false,
    this.invert = false,
    this.text = 'MyApp',
  });

  final double size;
  final bool showText;
  final bool invert;
  final String text;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: invert
              ? const [Colors.white, Color(0xFFE0E7FF)]
              : const [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: invert
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withAlpha(70),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.5,
        color: invert ? AppColors.primary : Colors.white,
      ),
    );

    if (!showText) return mark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.22),
        Text(
          text,
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: invert ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}