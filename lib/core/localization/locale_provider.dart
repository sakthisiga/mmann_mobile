import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialLocaleProvider = Provider<Locale>((ref) => const Locale('ta'));

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final initial = ref.watch(initialLocaleProvider);
  return LocaleNotifier(initial);
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _prefKey = 'selected_language';

  LocaleNotifier([super.initialLocale = const Locale('ta')]) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_prefKey);
    if (savedLang != null && ['ta', 'te', 'kn', 'ml', 'en'].contains(savedLang)) {
      state = Locale(savedLang);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (['ta', 'te', 'kn', 'ml', 'en'].contains(newLocale.languageCode)) {
      state = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newLocale.languageCode);
    }
  }
}
