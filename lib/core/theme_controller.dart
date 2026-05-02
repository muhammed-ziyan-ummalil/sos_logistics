// Identical pattern to sosagent_flutter/lib/utility/theme_controller.dart.
// ValueNotifier<ThemeMode> backed by SharedPreferences.
// Same key ('app_theme_mode') so preference is portable if ever shared.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  static const String _kKey = 'app_theme_mode';

  ThemeController() : super(ThemeMode.dark);

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kKey);
    if (saved != null) value = _fromString(saved);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, _toString(mode));
  }

  static ThemeMode _fromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };

  static String label(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        _ => 'System',
      };
}

// Global singleton — UI layer only
final themeController = ThemeController();
