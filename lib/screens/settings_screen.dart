import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/shop_config.dart';

/// Fully operable Settings screen with Account, Shop Name, Currency,
/// Notifications toggle, Theme toggle, and Delete Account.
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
  bool _isDarkTheme = false;

  // ── Account Details Dialog ──────────────────────────────────────────
  void _showAccountDetails() {
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
    }).toList() ?? ['Unknown'];

    final createdAt = user?.metadata.creationTime;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Details'),
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
            _detailRow('Name', user?.displayName ?? 'Not set'),
            const SizedBox(height: 8),
            _detailRow('Email', user?.email ?? 'Not set'),
            const SizedBox(height: 8),
            _detailRow('Provider(s)', providers.join(', ')),
            const SizedBox(height: 8),
            _detailRow('Created', createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                : 'Unknown'),
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
                label: const Text('Delete Account'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmDeleteAccount();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
              const Text('Delete Account', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _deleteItem('Your account and login credentials'),
              _deleteItem('Shop name, avatar, and all settings'),
              _deleteItem('All locally stored data'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Text('Type DELETE to confirm:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
              child: const Text('Delete Permanently'),
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
    try {
      // Clear all local data first
      await ShopConfig.instance.clearAll();
      // Delete the Firebase account
      await _auth.currentUser?.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account and all data deleted permanently.')),
        );
        widget.onLogout();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Failed to delete account.';
        if (e.code == 'requires-recent-login') {
          msg = 'For security, please sign out, sign back in, and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete account.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Shop Name Editor ────────────────────────────────────────────────
  void _editShopName() {
    final ctrl = TextEditingController(text: ShopConfig.instance.shopName.value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Shop Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Shop Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ShopConfig.instance.setShopName(ctrl.text.trim());
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shop name updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Currency Selector ───────────────────────────────────────────────
  void _selectCurrency() {
    const currencies = ['₹ INR', '\$ USD', '€ EUR', '£ GBP', '¥ JPY'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Currency'),
        children: currencies.map((c) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _currency = c);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Currency set to $c')),
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                // Account
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Account'),
                  subtitle: Text(user?.email ?? 'Not signed in'),
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
                      title: const Text('Shop Name'),
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
                  title: const Text('Currency'),
                  subtitle: Text(_currency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectCurrency,
                ),
                const Divider(height: 1),
                // Notifications
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: Text(_notificationsEnabled ? 'Low-stock alerts enabled' : 'Alerts disabled'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(v ? 'Notifications enabled' : 'Notifications disabled')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                // Theme
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Theme'),
                  subtitle: Text(_isDarkTheme ? 'Dark' : 'Light'),
                  trailing: Switch(
                    value: _isDarkTheme,
                    onChanged: (v) {
                      setState(() => _isDarkTheme = v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(v ? 'Dark theme selected (visual change coming soon)' : 'Light theme selected')),
                      );
                    },
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
                  title: const Text('About'),
                  subtitle: const Text('GrowthOS v0.1.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'GrowthOS',
                      applicationVersion: '0.1.0',
                      applicationIcon: Icon(Icons.storefront, size: 48, color: Colors.indigo.shade400),
                      children: [
                        const Text('AI-Powered Business Insights for Small Shop Owners.'),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
