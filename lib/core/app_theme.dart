import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xff2f6f5e);
  static const primaryDark = Color(0xff245648);
  static const primarySoft = Color(0xffe4f0eb);
  static const background = Color(0xfff7f5ef);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xffeef2ef);
  static const border = Color(0xffdce5e0);
  static const textPrimary = Color(0xff17231f);
  static const textSecondary = Color(0xff5e6d66);
  static const textTertiary = Color(0xff8b9992);
  static const error = Color(0xffb42318);
  static const danger = Color(0xffb42318);
  static const errorSoft = Color(0xffffebe9);
  static const success = Color(0xff18794e);
  static const successSoft = Color(0xffe7f6ed);
  static const warning = Color(0xffa15c00);
  static const warningSoft = Color(0xfffff1d6);
}

class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const sm = 8.0;
  static const m = 12.0;
  static const md = 12.0;
  static const l = 16.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const screen = 20.0;
}

class AppRadius {
  static const s = 8.0;
  static const sm = 8.0;
  static const m = 12.0;
  static const md = 12.0;
  static const l = 18.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

const kMinTouchTarget = 48.0;

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySoft,
        ),
      );
}
