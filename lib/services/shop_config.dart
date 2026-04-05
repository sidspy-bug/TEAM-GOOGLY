import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Singleton that holds shop-level configuration.
/// Data is persisted to the backend SQLite DB (via API) so it survives across
/// sessions and devices. SharedPreferences is used as a local cache only.
class ShopConfig {
  ShopConfig._();
  static final ShopConfig _instance = ShopConfig._();
  static ShopConfig get instance => _instance;

  String _uid = '';

  String get _keyShopName => 'shop_name_$_uid';
  String get _keyOnboarded => 'onboarded_$_uid';
  String get _keyAvatarIndex => 'avatar_index_$_uid';

  final ValueNotifier<String> shopName = ValueNotifier<String>('My Shop');
  final ValueNotifier<int> avatarIndex = ValueNotifier<int>(-1);
  bool _onboarded = false;
  bool get onboarded => _onboarded;

  /// Call at app startup (no user yet) — loads defaults.
  Future<void> load() async {
    shopName.value = 'My Shop';
    avatarIndex.value = -1;
    _onboarded = false;
  }

  /// Load config for a specific user UID.
  /// Tries backend first, falls back to local SharedPreferences cache.
  Future<void> loadForUser(String uid) async {
    _uid = uid;
    final prefs = await SharedPreferences.getInstance();

    // Try to load from backend API
    try {
      final data = await ApiService().get('/user/settings');
      shopName.value = data['shopName'] ?? 'My Shop';
      _onboarded = data['onboarded'] == true;
      avatarIndex.value = data['avatarIndex'] ?? -1;

      // Cache locally
      await prefs.setString(_keyShopName, shopName.value);
      await prefs.setBool(_keyOnboarded, _onboarded);
      await prefs.setInt(_keyAvatarIndex, avatarIndex.value);
      return;
    } catch (_) {
      // Backend unavailable — fall back to local cache
    }

    shopName.value = prefs.getString(_keyShopName) ?? 'My Shop';
    _onboarded = prefs.getBool(_keyOnboarded) ?? false;
    avatarIndex.value = prefs.getInt(_keyAvatarIndex) ?? -1;
  }

  Future<void> setShopName(String name) async {
    shopName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyShopName, name);
    // Sync to backend
    try { await ApiService().put('/user/settings', body: {'shopName': name}); } catch (_) {}
  }

  Future<void> markOnboarded() async {
    _onboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
    // Sync to backend
    try { await ApiService().put('/user/settings', body: {'onboarded': true}); } catch (_) {}
  }

  Future<void> setAvatarIndex(int index) async {
    avatarIndex.value = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAvatarIndex, index);
    // Sync to backend
    try { await ApiService().put('/user/settings', body: {'avatarIndex': index}); } catch (_) {}
  }

  /// Clears all data for the current user (used on account deletion).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyShopName);
    await prefs.remove(_keyOnboarded);
    await prefs.remove(_keyAvatarIndex);
    _onboarded = false;
    shopName.value = 'My Shop';
    avatarIndex.value = -1;
    _uid = '';
  }
}
