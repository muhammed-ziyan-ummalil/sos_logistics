import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sossss_logistics/core/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('light theme uses emerald primary and Material3', (tester) async {
    final t = buildAppThemeLight();
    expect(t.useMaterial3, true);
    expect(t.colorScheme.primary, AppDesignTokens.lightPrimary);
    expect(AppDesignTokens.lightPrimary, const Color(0xFF1F6F5B));
    // drain async font-load side effects so they don't bleed into the next test
    await tester.pumpAndSettle();
  });

  testWidgets('dark theme uses emerald-400 primary', (tester) async {
    final t = buildAppThemeDark();
    expect(t.colorScheme.primary, AppDesignTokens.darkPrimary);
    expect(AppDesignTokens.darkPrimary, const Color(0xFF34D399));
    await tester.pumpAndSettle();
  });

  test('back-compat AppColors.primary is now emerald, not blue', () {
    expect(AppColors.primary, isNot(const Color(0xFF0B3D91)));
    expect(AppLightColors.primary, const Color(0xFF1F6F5B));
  });

  test('spacing + radius tokens present', () {
    expect(AppDesignTokens.spacingL, 16.0);
    expect(AppDesignTokens.radiusCard, 16.0);
  });
}
