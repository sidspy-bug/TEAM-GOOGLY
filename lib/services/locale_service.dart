import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Singleton that persists the user's language preference.
/// Stores the locale code in SharedPreferences and syncs to the backend
/// `/user/settings` endpoint so the choice survives across devices.
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _prefKey = 'locale_code';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('mr'),
  ];

  /// Currently selected locale — listen to this in the UI.
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  /// Load the persisted locale at startup (no user context required).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey) ?? 'en';
    locale.value = Locale(code);
  }

  /// Load locale for a specific user, merging backend preference with the
  /// local cache (backend wins when available).
  Future<void> loadForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await ApiService().get('/user/settings');
      final code = (data['language'] as String?)?.isNotEmpty == true
          ? data['language'] as String
          : prefs.getString(_prefKey) ?? 'en';
      await prefs.setString(_prefKey, code);
      locale.value = Locale(code);
    } catch (_) {
      final code = prefs.getString(_prefKey) ?? 'en';
      locale.value = Locale(code);
    }
  }

  /// Change the app language and persist the choice.
  Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
    try {
      await ApiService().put('/user/settings',
          body: {'language': newLocale.languageCode});
    } catch (_) {}
  }
}
