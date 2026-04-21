import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFFFF6B6B);
  static const accent = Color(0xFF4ECDC4);
  static const gold = Color(0xFFFFD93D);
  static const goldDark = Color(0xFFC8A830);
  static const correct = Color(0xFF6BCB77);
  static const wrong = Color(0xFFFF6B6B);

  // Brand colors — used throughout nav, headers, and primary UI
  static const teal = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);
  static const tealLight = Color(0xFF4DD0C4);

  // Hero/CTA — logo and primary action buttons
  static const hero = Color(0xFFE8524A);

  // Status/badge colors
  static const amber = Color(0xFFFFB300);
  static const pink = Color(0xFFF45B8C);

  static const background = Color(0xFFE8F5F3);
  static const surface = Color(0xFFF5FFFE);
  static const cream = Color(0xFFF5FAF7);
  static const card = Colors.white;

  // Borders
  static const border = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFFD1D5DB);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);

  static const categoryPrivacy = Color(0xFF7C4DFF);
  static const categoryPasswords = Color(0xFF00BCD4);
  static const categoryCyberbullying = Color(0xFFFF5252);
  static const categorySocialMedia = Color(0xFFFFD740);
  static const categoryPhishing = Color(0xFFFF6D00);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
      TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}