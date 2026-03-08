import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that persists and exposes the app's [ThemeMode].
///
/// Usage:
///   await ThemeService.instance.load();          // once at startup
///   ThemeService.instance.themeMode             // ValueNotifier to listen to
///   await ThemeService.instance.setThemeMode(ThemeMode.dark);
class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _key = 'app_theme_mode';

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Load the persisted theme preference. Call once at app startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    themeMode.value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  /// Persist and broadcast a new [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
