import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../services/shop_config.dart';
import '../services/theme_service.dart';

/// Fully operable Settings screen with Account, Shop Name, Currency,
/// Notifications toggle, Theme toggle, Language selector, and Delete Account.
class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;

  String _currency = '₹ INR';
  bool _notificationsEnabled = true;

  // ── Account Details Dialog ──────────────────────────────────────────
  void _showAccountDetails() {
    final l = AppLocalizations.of(context);
    final user = _auth.currentUser;
    final providers = user?.providerData.map((p) {
      switch (p.providerId) {
        case 'password':
          return 'Email/Password';
        case 'google.com':
          return 'Google';
        case 'facebook.com':
          return 'Facebook';
        case 'phone':
          return 'Phone';
        default:
          return p.providerId;
      }
    }).toList() ?? [l.unknown];

    final createdAt = user?.metadata.creationTime;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.accountDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                backgroundColor: Colors.indigo.shade100,
                child: user?.photoURL == null
                    ? Text(
                        _initials(user),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(l.nameLabel, user?.displayName ?? l.notSet),
            const SizedBox(height: 8),
            _detailRow(l.email, user?.email ?? l.notSet),
            const SizedBox(height: 8),
            _detailRow(l.providerLabel, providers.join(', ')),
            const SizedBox(height: 8),
            _detailRow(l.createdLabel, createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                : l.unknown),
            const SizedBox(height: 20),
            // Delete Account button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.delete_forever),
                label: Text(l.deleteAccount),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDeleteAccount();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  String _initials(User? user) {
    final name = user?.displayName ?? user?.email ?? 'U';
    return name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  // ── Delete Account ──────────────────────────────────────────────────
  void _confirmDeleteAccount() {
    final l = AppLocalizations.of(context);
    final confirmCtrl = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 8),
              Text(l.deleteAccount, style: const TextStyle(color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.thisWillDelete,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _deleteItem(l.deleteItemCredentials),
              _deleteItem(l.deleteItemShopSettings),
              _deleteItem(l.deleteItemLocalData),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  l.cannotBeUndone,
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.typeDeleteToConfirm, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) {
                  setDialogState(() => canDelete = v.trim().toUpperCase() == 'DELETE');
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canDelete ? Colors.red : Colors.grey.shade300,
                foregroundColor: Colors.white,
              ),
              onPressed: canDelete
                  ? () async {
                      Navigator.pop(ctx);
                      await _deleteAccount();
                    }
                  : null,
              child: Text(l.deletePermanently),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.remove_circle, size: 14, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context);
    try {
      await ShopConfig.instance.clearAll();
      await _auth.currentUser?.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.deleteAccount}: ${l.success}')),
        );
        widget.onLogout();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = l.error;
        if (e.code == 'requires-recent-login') {
          msg = l.requiresRecentLogin;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.error), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Shop Name Editor ────────────────────────────────────────────────
  void _editShopName() {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: ShopConfig.instance.shopName.value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editShopName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l.shopName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ShopConfig.instance.setShopName(ctrl.text.trim());
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.shopNameUpdated)),
                );
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  // ── Currency Selector ───────────────────────────────────────────────
  void _selectCurrency() {
    final l = AppLocalizations.of(context);
    const currencies = ['₹ INR', '\$ USD', '€ EUR', '£ GBP', '¥ JPY'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.selectCurrency),
        children: currencies.map((c) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _currency = c);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l.currency}: $c')),
              );
            },
            child: Row(
              children: [
                if (c == _currency) const Icon(Icons.check, color: Colors.indigo, size: 18),
                if (c == _currency) const SizedBox(width: 8),
                Text(c, style: TextStyle(fontWeight: c == _currency ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Language Selector ───────────────────────────────────────────────
  void _selectLanguage() {
    final l = AppLocalizations.of(context);
    final locales = LocaleService.supportedLocales;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.selectLanguage),
        children: locales.map((locale) {
          final isCurrent = LocaleService.instance.locale.value.languageCode == locale.languageCode;
          final name = l.languageName(locale.languageCode);
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocaleService.instance.setLocale(locale);
            },
            child: Row(
              children: [
                if (isCurrent) const Icon(Icons.check, color: Colors.indigo, size: 18),
                if (isCurrent) const SizedBox(width: 8),
                if (!isCurrent) const SizedBox(width: 26),
                Text(name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = _auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.settings, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                // Account
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(l.account),
                  subtitle: Text(user?.email ?? l.notSignedIn),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showAccountDetails,
                ),
                const Divider(height: 1),
                // Shop Name
                ValueListenableBuilder<String>(
                  valueListenable: ShopConfig.instance.shopName,
                  builder: (_, shopName, __) {
                    return ListTile(
                      leading: const Icon(Icons.store),
                      title: Text(l.shopName),
                      subtitle: Text(shopName),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: _editShopName,
                    );
                  },
                ),
                const Divider(height: 1),
                // Currency
                ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: Text(l.currency),
                  subtitle: Text(_currency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectCurrency,
                ),
                const Divider(height: 1),
                // Language
                ValueListenableBuilder<Locale>(
                  valueListenable: LocaleService.instance.locale,
                  builder: (_, locale, __) {
                    return ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l.language),
                      subtitle: Text(l.languageName(locale.languageCode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectLanguage,
                    );
                  },
                ),
                const Divider(height: 1),
                // Notifications
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(l.notifications),
                  subtitle: Text(_notificationsEnabled ? l.lowStockAlertsEnabled : l.alertsDisabled),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(v ? l.notificationsEnabledMsg : l.notificationsDisabledMsg)),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                // Theme
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Theme'),
                  subtitle: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeService.instance.themeMode,
                    builder: (_, mode, __) => Text(mode == ThemeMode.dark ? 'Dark' : 'Light'),
                  ),
                  trailing: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeService.instance.themeMode,
                    builder: (_, mode, __) => Switch(
                      value: mode == ThemeMode.dark,
                      onChanged: (v) async {
                        await ThemeService.instance.setThemeMode(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(v ? 'Dark theme enabled' : 'Light theme enabled')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.about),
                  subtitle: Text(l.aboutVersion),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: l.appName,
                      applicationVersion: '0.1.0',
                      applicationIcon: Icon(Icons.storefront, size: 48, color: Colors.indigo.shade400),
                      children: [
                        Text(l.aboutDescription),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(l.logout, style: const TextStyle(color: Colors.red)),
                  onTap: widget.onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
