import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// AppDesignTokens — single source of truth (ported from
// sosfarmer_flutter / sosagent_flutter; Deep Emerald / Slate)
// ─────────────────────────────────────────────────────────────
class AppDesignTokens {
  // Light palette
  static const Color lightBackground    = Color(0xFFF4F6F8);
  static const Color lightCard          = Color(0xFFFFFFFF);
  static const Color lightPrimary       = Color(0xFF1F6F5B);
  static const Color lightPrimaryDark   = Color(0xFF155446);
  static const Color lightAccent        = Color(0xFF2DD4BF);
  static const Color lightTextPrimary   = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder        = Color(0xFFE2E8F0);
  static const Color lightSurface       = Color(0xFFF8FAFC);

  // Dark palette
  static const Color darkBackground     = Color(0xFF0F172A);
  static const Color darkCard           = Color(0xFF1E293B);
  static const Color darkPrimary        = Color(0xFF34D399);
  static const Color darkAccent         = Color(0xFF2DD4BF);
  static const Color darkTextPrimary    = Color(0xFFF8FAFC);
  static const Color darkTextSecondary  = Color(0xFF94A3B8);
  static const Color darkBorder         = Color(0xFF334155);
  static const Color darkSurface        = Color(0xFF0F172A);

  // Semantic (shared)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color errorLight = Color(0xFFDC2626);
  static const Color errorDark  = Color(0xFFF87171);

  // Radius
  static const double radiusXS    = 8.0;
  static const double radiusS     = 12.0;
  static const double radiusInput = 12.0;
  static const double radiusCard  = 16.0;
  static const double radiusNavBar = 0.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS  = 8.0;
  static const double spacingM  = 12.0;
  static const double spacingL  = 16.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;

  // Icon sizes
  static const double iconSizeS = 18.0;
  static const double iconSizeM = 22.0;
  static const double iconSizeL = 28.0;

  // Elevation
  static const double elevationCard  = 0.0;
  static const double elevationModal = 0.0;

  // Shadows
  static List<BoxShadow> get cardShadowLight => [
        BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2)),
      ];
  static List<BoxShadow> get cardShadowDark => [
        BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 2)),
      ];
  static List<BoxShadow> get navBarShadow => [
        BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.10),
            blurRadius: 0,
            offset: const Offset(0, -1)),
      ];
  static List<BoxShadow> get walletGlowDark => [
        BoxShadow(
            color: const Color(0xFF34D399).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 8)),
      ];
  static List<BoxShadow> get walletGlowLight => [
        BoxShadow(
            color: const Color(0xFF1F6F5B).withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 6)),
      ];

  // Context-aware shadow helpers
  static List<BoxShadow> cardShadow(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? cardShadowDark : cardShadowLight;
  static List<BoxShadow> walletGlow(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark ? walletGlowDark : walletGlowLight;
}

// ─────────────────────────────────────────────────────────────
// TextTheme helper
// ─────────────────────────────────────────────────────────────
TextTheme _buildTextTheme(Color primary, Color secondary) {
  return TextTheme(
    displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.8, height: 1.15),
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary, height: 1.2),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary, height: 1.3),
    titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary, height: 1.3),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: primary, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primary, height: 1.4),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: secondary, height: 1.4),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: secondary, height: 1.4),
  );
}

// ─────────────────────────────────────────────────────────────
// Light theme
// ─────────────────────────────────────────────────────────────
ThemeData buildAppThemeLight() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppDesignTokens.lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD1FAE5),
      onPrimaryContainer: AppDesignTokens.lightPrimaryDark,
      secondary: AppDesignTokens.lightAccent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFCCFBF1),
      onSecondaryContainer: Color(0xFF134E4A),
      surface: AppDesignTokens.lightCard,
      onSurface: AppDesignTokens.lightTextPrimary,
      surfaceContainerHighest: AppDesignTokens.lightBackground,
      error: AppDesignTokens.errorLight,
      onError: Colors.white,
      outline: AppDesignTokens.lightBorder,
      shadow: Color(0x0A000000),
    ),
    scaffoldBackgroundColor: AppDesignTokens.lightBackground,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      _buildTextTheme(AppDesignTokens.lightTextPrimary, AppDesignTokens.lightTextSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppDesignTokens.lightCard,
      foregroundColor: AppDesignTokens.lightTextPrimary,
      elevation: 0,
      centerTitle: false,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: AppDesignTokens.lightTextPrimary),
      iconTheme: const IconThemeData(color: AppDesignTokens.lightTextPrimary, size: AppDesignTokens.iconSizeM),
    ),
    cardTheme: const CardThemeData(
      color: AppDesignTokens.lightCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusCard))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDesignTokens.lightPrimary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput))),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDesignTokens.lightPrimary,
        side: const BorderSide(color: AppDesignTokens.lightBorder, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput))),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDesignTokens.lightSurface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.lightBorder)),
      enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.lightBorder, width: 1.2)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.lightPrimary, width: 1.8)),
      errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.errorLight)),
      focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.errorLight, width: 1.8)),
      hintStyle: const TextStyle(color: AppDesignTokens.lightTextSecondary, fontSize: 14),
      errorStyle: const TextStyle(color: AppDesignTokens.errorLight, fontSize: 12),
      prefixIconColor: AppDesignTokens.lightTextSecondary,
      suffixIconColor: AppDesignTokens.lightTextSecondary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppDesignTokens.lightCard,
      selectedItemColor: AppDesignTokens.lightPrimary,
      unselectedItemColor: AppDesignTokens.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppDesignTokens.lightBorder, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusXS))),
      backgroundColor: AppDesignTokens.lightTextPrimary,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusCard))),
      backgroundColor: AppDesignTokens.lightCard,
      elevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppDesignTokens.lightPrimary),
    chipTheme: ChipThemeData(
      backgroundColor: AppDesignTokens.lightBackground,
      selectedColor: const Color(0xFFD1FAE5),
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppDesignTokens.lightTextPrimary),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)), side: BorderSide(color: AppDesignTokens.lightBorder)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Dark theme
// ─────────────────────────────────────────────────────────────
ThemeData buildAppThemeDark() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppDesignTokens.darkPrimary,
      onPrimary: Color(0xFF052E16),
      primaryContainer: Color(0xFF064E3B),
      onPrimaryContainer: AppDesignTokens.darkPrimary,
      secondary: AppDesignTokens.darkAccent,
      onSecondary: Color(0xFF042F2E),
      secondaryContainer: Color(0xFF134E4A),
      onSecondaryContainer: AppDesignTokens.darkAccent,
      surface: AppDesignTokens.darkCard,
      onSurface: AppDesignTokens.darkTextPrimary,
      surfaceContainerHighest: AppDesignTokens.darkBackground,
      error: AppDesignTokens.errorDark,
      onError: Color(0xFF7F1D1D),
      outline: AppDesignTokens.darkBorder,
      shadow: Colors.black54,
    ),
    scaffoldBackgroundColor: AppDesignTokens.darkBackground,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      _buildTextTheme(AppDesignTokens.darkTextPrimary, AppDesignTokens.darkTextSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppDesignTokens.darkBackground,
      foregroundColor: AppDesignTokens.darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w600, color: AppDesignTokens.darkTextPrimary),
      iconTheme: const IconThemeData(color: AppDesignTokens.darkTextPrimary, size: AppDesignTokens.iconSizeM),
    ),
    cardTheme: const CardThemeData(
      color: AppDesignTokens.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusCard))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDesignTokens.darkPrimary,
        foregroundColor: const Color(0xFF052E16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput))),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDesignTokens.darkPrimary,
        side: const BorderSide(color: AppDesignTokens.darkBorder, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput))),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDesignTokens.darkCard,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.darkBorder)),
      enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.darkBorder, width: 1.2)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.darkPrimary, width: 1.8)),
      errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.errorDark)),
      focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusInput)), borderSide: BorderSide(color: AppDesignTokens.errorDark, width: 1.8)),
      hintStyle: const TextStyle(color: AppDesignTokens.darkTextSecondary, fontSize: 14),
      errorStyle: const TextStyle(color: AppDesignTokens.errorDark, fontSize: 12),
      prefixIconColor: AppDesignTokens.darkTextSecondary,
      suffixIconColor: AppDesignTokens.darkTextSecondary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppDesignTokens.darkCard,
      selectedItemColor: AppDesignTokens.darkPrimary,
      unselectedItemColor: AppDesignTokens.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppDesignTokens.darkBorder, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusXS))),
      backgroundColor: AppDesignTokens.darkCard,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: AppDesignTokens.darkTextPrimary, fontSize: 14),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDesignTokens.radiusCard))),
      backgroundColor: AppDesignTokens.darkCard,
      elevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppDesignTokens.darkPrimary),
    chipTheme: ChipThemeData(
      backgroundColor: AppDesignTokens.darkCard,
      selectedColor: const Color(0xFF064E3B),
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppDesignTokens.darkTextPrimary),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)), side: BorderSide(color: AppDesignTokens.darkBorder)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
  );
}

ThemeData buildAppTheme() => buildAppThemeLight();

// ─────────────────────────────────────────────────────────────
// Back-compat aliases — existing screens read these directly.
// Repointed to emerald tokens so old code recolors with no edits.
// Later phases migrate screens to colorScheme / widget library.
// ─────────────────────────────────────────────────────────────
class AppColors {
  static const background    = AppDesignTokens.darkBackground;
  static const surface       = AppDesignTokens.darkCard;
  static const card          = AppDesignTokens.darkCard;
  static const primary       = AppDesignTokens.darkPrimary;
  static const primaryLight  = AppDesignTokens.darkAccent;
  static const accent        = AppDesignTokens.darkAccent;
  static const success       = AppDesignTokens.success;
  static const warning       = AppDesignTokens.warning;
  static const error         = AppDesignTokens.errorDark;
  static const textPrimary   = AppDesignTokens.darkTextPrimary;
  static const textSecondary = AppDesignTokens.darkTextSecondary;
  static const divider       = AppDesignTokens.darkBorder;
}

class AppLightColors {
  static const background    = AppDesignTokens.lightBackground;
  static const surface       = AppDesignTokens.lightCard;
  static const card          = AppDesignTokens.lightCard;
  static const primary       = AppDesignTokens.lightPrimary;
  static const primaryLight  = AppDesignTokens.lightAccent;
  static const accent        = AppDesignTokens.lightAccent;
  static const success       = AppDesignTokens.success;
  static const warning       = AppDesignTokens.warning;
  static const error         = AppDesignTokens.errorLight;
  static const textPrimary   = AppDesignTokens.lightTextPrimary;
  static const textSecondary = AppDesignTokens.lightTextSecondary;
  static const divider       = AppDesignTokens.lightBorder;
}

class AppTheme {
  static bool _dark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;
  static Color bg(BuildContext ctx) => _dark(ctx) ? AppColors.background : AppLightColors.background;
  static Color surface(BuildContext ctx) => _dark(ctx) ? AppColors.surface : AppLightColors.surface;
  static Color card(BuildContext ctx) => _dark(ctx) ? AppColors.card : AppLightColors.card;
  static Color primary(BuildContext ctx) => _dark(ctx) ? AppColors.primary : AppLightColors.primary;
  static Color accent(BuildContext ctx) => _dark(ctx) ? AppColors.accent : AppLightColors.accent;
  static Color success(BuildContext ctx) => AppDesignTokens.success;
  static Color warning(BuildContext ctx) => AppDesignTokens.warning;
  static Color error(BuildContext ctx) => _dark(ctx) ? AppColors.error : AppLightColors.error;
  static Color textPrimary(BuildContext ctx) => _dark(ctx) ? AppColors.textPrimary : AppLightColors.textPrimary;
  static Color textSecondary(BuildContext ctx) => _dark(ctx) ? AppColors.textSecondary : AppLightColors.textSecondary;
  static Color divider(BuildContext ctx) => _dark(ctx) ? AppColors.divider : AppLightColors.divider;
}
