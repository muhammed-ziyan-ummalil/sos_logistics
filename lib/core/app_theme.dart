import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Dark palette (unchanged) ─────────────────────────────────────────────────
class AppColors {
  static const background    = Color(0xFF000B18);
  static const surface       = Color(0xFF071428);
  static const card          = Color(0xFF0D1F3C);
  static const primary       = Color(0xFF0B3D91);
  static const primaryLight  = Color(0xFF1A5DC8);
  static const accent        = Color(0xFF00D4FF);
  static const success       = Color(0xFF22C55E);
  static const warning       = Color(0xFFF59E0B);
  static const error         = Color(0xFFEF4444);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF94A3B8);
  static const divider       = Color(0xFF1E3A5F);
}

// ── Light palette ─────────────────────────────────────────────────────────────
class AppLightColors {
  static const background    = Color(0xFFF0F4FF);
  static const surface       = Color(0xFFFFFFFF);
  static const card          = Color(0xFFFFFFFF);
  static const primary       = Color(0xFF0B3D91);
  static const primaryLight  = Color(0xFF1A5DC8);
  static const accent        = Color(0xFF0284C7);
  static const success       = Color(0xFF16A34A);
  static const warning       = Color(0xFFD97706);
  static const error         = Color(0xFFDC2626);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const divider       = Color(0xFFE2E8F0);
}

// ── Helpers — read from context so screens stay theme-aware ─────────────────
class AppTheme {
  static Color bg(BuildContext ctx) =>
      _dark(ctx) ? AppColors.background : AppLightColors.background;
  static Color surface(BuildContext ctx) =>
      _dark(ctx) ? AppColors.surface : AppLightColors.surface;
  static Color card(BuildContext ctx) =>
      _dark(ctx) ? AppColors.card : AppLightColors.card;
  static Color primary(BuildContext ctx) =>
      _dark(ctx) ? AppColors.primary : AppLightColors.primary;
  static Color accent(BuildContext ctx) =>
      _dark(ctx) ? AppColors.accent : AppLightColors.accent;
  static Color success(BuildContext ctx) =>
      _dark(ctx) ? AppColors.success : AppLightColors.success;
  static Color warning(BuildContext ctx) =>
      _dark(ctx) ? AppColors.warning : AppLightColors.warning;
  static Color error(BuildContext ctx) =>
      _dark(ctx) ? AppColors.error : AppLightColors.error;
  static Color textPrimary(BuildContext ctx) =>
      _dark(ctx) ? AppColors.textPrimary : AppLightColors.textPrimary;
  static Color textSecondary(BuildContext ctx) =>
      _dark(ctx) ? AppColors.textSecondary : AppLightColors.textSecondary;
  static Color divider(BuildContext ctx) =>
      _dark(ctx) ? AppColors.divider : AppLightColors.divider;

  static bool _dark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;
}

// ── Dark theme (pre-existing, unchanged) ─────────────────────────────────────
ThemeData buildAppThemeDark() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 0.8),
      ),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

// ── Light theme ───────────────────────────────────────────────────────────────
ThemeData buildAppThemeLight() {
  final base = ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: AppLightColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppLightColors.primary,
      secondary: AppLightColors.accent,
      surface: AppLightColors.surface,
      error: AppLightColors.error,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppLightColors.textPrimary,
      displayColor: AppLightColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppLightColors.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppLightColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppLightColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppLightColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppLightColors.textPrimary,
        side: const BorderSide(color: AppLightColors.divider),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppLightColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppLightColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppLightColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppLightColors.primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.poppins(color: AppLightColors.textSecondary, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: AppLightColors.textSecondary, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: AppLightColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppLightColors.divider, width: 0.8),
      ),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppLightColors.surface,
      selectedItemColor: AppLightColors.primary,
      unselectedItemColor: AppLightColors.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppLightColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

// Backward-compat alias used by existing screens
ThemeData buildAppTheme() => buildAppThemeDark();
