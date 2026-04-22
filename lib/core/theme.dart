import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────────────────
  static const blue = Color(0xFF1CB0F6);
  static const blueDark = Color(0xFF0E8FC7);
  static const blueLight = Color(0xFFD4F0FD);

  static const green = Color(0xFF58CC02);
  static const greenDark = Color(0xFF46A302);
  static const greenLight = Color(0xFFDDF5C1);

  static const red = Color(0xFFFF4B4B);
  static const redDark = Color(0xFFD93636);
  static const redLight = Color(0xFFFFE0E0);

  static const orange = Color(0xFFFF9600);
  static const orangeDark = Color(0xFFCC7800);

  static const gold = Color(0xFFFFD700);
  static const goldDark = Color(0xFFC8A830);

  // ── Brand teal (kept for backward compat) ────────────────────────────────
  static const teal = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);
  static const tealLight = Color(0xFF4DD0C4);

  // ── Legacy aliases so existing screens compile unchanged ─────────────────
  static const primary = blue;
  static const secondary = Color(0xFFFF6B6B);
  static const accent = Color(0xFF4ECDC4);
  static const hero = Color(0xFFE8524A);
  static const amber = Color(0xFFFFB300);
  static const pink = Color(0xFFF45B8C);
  static const correct = green;
  static const wrong = red;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const background = Color(0xFFF7F7F7);
  static const surface = Colors.white;
  static const cream = Color(0xFFF5FAF7);
  static const card = Colors.white;

  // ── Borders ──────────────────────────────────────────────────────────────
  static const border = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFFD1D5DB);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF3C3C3C);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);

  // ── Category palette ─────────────────────────────────────────────────────
  static const categoryPrivacy = Color(0xFF7C4DFF);
  static const categoryPasswords = Color(0xFF00BCD4);
  static const categoryCyberbullying = Color(0xFFFF5252);
  static const categorySocialMedia = Color(0xFFFFAB00);
  static const categoryPhishing = Color(0xFFFF6D00);
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.light,
        primary: AppColors.blue,
        secondary: AppColors.green,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final nunito = GoogleFonts.nunitoTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: nunito.copyWith(
        displayLarge: nunito.displayLarge?.copyWith(fontWeight: FontWeight.w900),
        displayMedium: nunito.displayMedium?.copyWith(fontWeight: FontWeight.w900),
        titleLarge: nunito.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: nunito.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: nunito.labelLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
        bodyLarge: nunito.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: nunito.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
