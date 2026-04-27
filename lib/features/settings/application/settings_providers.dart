import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

// ─── SharedPreferences Provider ──────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences before using');
});

// ─── Language Settings ───────────────────────────────────────────────────────

class LanguageNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs)
      : super(
          Locale(_prefs.getString(AppConstants.prefLanguageCode) ?? 'ar'),
        );

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(AppConstants.prefLanguageCode, languageCode);
    state = Locale(languageCode);
  }

  bool get isArabic => state.languageCode == 'ar';

  Future<void> toggleLanguage() async {
    final newCode = isArabic ? 'en' : 'ar';
    await setLanguage(newCode);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});

// ─── Theme Settings ──────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final value = prefs.getString(AppConstants.prefThemeMode);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(
        AppConstants.prefThemeMode,
        mode == ThemeMode.dark
            ? 'dark'
            : mode == ThemeMode.light
                ? 'light'
                : 'system');
    state = mode;
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});
