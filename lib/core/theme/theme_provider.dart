import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final initial = ref.watch(initialThemeModeProvider);
  return ThemeModeNotifier(initial);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _prefKey = 'selected_theme_mode';

  ThemeModeNotifier([super.initialMode = ThemeMode.light]) {
    _loadSavedThemeMode();
  }

  Future<void> _loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'system') {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefKey, value);
  }

  Future<void> toggleDarkLight(bool currentlyDark) async {
    await setThemeMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }
}

