import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that holds shop-level configuration.
/// Data is scoped per user UID so different accounts don't share data.
/// Uses ValueNotifier so widgets can reactively rebuild via ValueListenableBuilder.
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
    // Just reset to defaults; actual data loads when user signs in
    shopName.value = 'My Shop';
    avatarIndex.value = -1;
    _onboarded = false;
  }

  /// Load config for a specific user UID.
  Future<void> loadForUser(String uid) async {
    _uid = uid;
    final prefs = await SharedPreferences.getInstance();
    shopName.value = prefs.getString(_keyShopName) ?? 'My Shop';
    _onboarded = prefs.getBool(_keyOnboarded) ?? false;
    avatarIndex.value = prefs.getInt(_keyAvatarIndex) ?? -1;
  }

  Future<void> setShopName(String name) async {
    shopName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyShopName, name);
  }

  Future<void> markOnboarded() async {
    _onboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
  }

  Future<void> setAvatarIndex(int index) async {
    avatarIndex.value = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAvatarIndex, index);
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
