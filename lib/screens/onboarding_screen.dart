import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/shop_config.dart';

/// Onboarding screen shown once after first sign-in.
/// Collects: display name, shop name, and profile picture.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  int _selectedAvatar = -1; // -1 = use existing / none
  bool _saving = false;
  int _step = 0; // 0 = name, 1 = shop, 2 = avatar

  static const _avatarIcons = [
    Icons.storefront,
    Icons.shopping_bag,
    Icons.local_cafe,
    Icons.restaurant,
    Icons.local_pharmacy,
    Icons.build,
    Icons.local_florist,
    Icons.sports_esports,
    Icons.auto_awesome,
    Icons.cake,
    Icons.local_grocery_store,
    Icons.devices,
  ];

  static const _avatarColors = [
    Color(0xFF5C6BC0), // indigo
    Color(0xFF26A69A), // teal
    Color(0xFFEF5350), // red
    Color(0xFFFF7043), // deep orange
    Color(0xFF66BB6A), // green
    Color(0xFF42A5F5), // blue
    Color(0xFFAB47BC), // purple
    Color(0xFFFFCA28), // amber
    Color(0xFF78909C), // blue grey
    Color(0xFFEC407A), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFF26C6DA), // cyan
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
    _shopCtrl.text = ShopConfig.instance.shopName.value;
    if (_shopCtrl.text == 'My Shop') _shopCtrl.text = '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shopCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Update display name
      if (_nameCtrl.text.trim().isNotEmpty) {
        await user?.updateDisplayName(_nameCtrl.text.trim());
      }
      // Save shop name
      final shopName = _shopCtrl.text.trim().isNotEmpty ? _shopCtrl.text.trim() : 'My Shop';
      await ShopConfig.instance.setShopName(shopName);
      // Save avatar selection
      if (_selectedAvatar >= 0) {
        await ShopConfig.instance.setAvatarIndex(_selectedAvatar);
      }
      await ShopConfig.instance.markOnboarded();
      await user?.reload();
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _next() {
    final l = AppLocalizations.of(context);
    if (_step == 0 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pleaseEnterName), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_step == 1 && _shopCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pleaseEnterShopName), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            margin: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GrowthOS branding
                Icon(Icons.storefront, size: 48, color: Colors.indigo.shade400),
                const SizedBox(height: 8),
                Text(l.appName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 4),
                Text(l.letsSetupStore, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 24),

                // Step indicators
                _buildStepIndicator(l),
                const SizedBox(height: 24),

                // Main card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _step == 0
                          ? _buildNameStep(l)
                          : _step == 1
                              ? _buildShopStep(l)
                              : _buildAvatarStep(l),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_step > 0)
                      TextButton.icon(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(l.back),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton(
                      onPressed: _saving ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_step < 2 ? l.next : l.getStarted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                if (_step == 2)
                  TextButton(
                    onPressed: _saving ? null : () {
                      setState(() => _selectedAvatar = -1);
                      _finish();
                    },
                    child: Text(l.skipForNow, style: TextStyle(color: Colors.grey.shade500)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(AppLocalizations l) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(0, l.yourName),
        _line(0),
        _dot(1, l.shopNameLabel),
        _line(1),
        _dot(2, l.profileLabel),
      ],
    );
  }

  Widget _dot(int index, String label) {
    final done = _step > index;
    final active = _step == index;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Colors.green : (active ? Colors.indigo : Colors.grey.shade200),
            border: Border.all(
              color: done ? Colors.green : (active ? Colors.indigo : Colors.grey.shade300),
              width: 2,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.grey.shade500)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.indigo : Colors.grey.shade500, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _line(int afterIndex) {
    final done = _step > afterIndex;
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: done ? Colors.green.shade300 : Colors.grey.shade300,
    );
  }

  // ── Step 1: Name ──────────────────────────────────────────────────
  Widget _buildNameStep(AppLocalizations l) {
    return Column(
      key: const ValueKey('name'),
      children: [
        Icon(Icons.person_outline, size: 48, color: Colors.indigo.shade300),
        const SizedBox(height: 16),
        Text(l.whatsYourName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l.nameDisplayedProfile, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 24),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l.fullName,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }

  // ── Step 2: Shop Name ─────────────────────────────────────────────
  Widget _buildShopStep(AppLocalizations l) {
    return Column(
      key: const ValueKey('shop'),
      children: [
        Icon(Icons.store, size: 48, color: Colors.indigo.shade300),
        const SizedBox(height: 16),
        Text(l.nameYourShop, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l.shopNameDisplayed, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 24),
        TextField(
          controller: _shopCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l.shopNameLabel,
            prefixIcon: const Icon(Icons.storefront),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
            hintText: 'e.g. Kumar General Store',
          ),
          onSubmitted: (_) => _next(),
        ),
      ],
    );
  }

  // ── Step 3: Avatar ────────────────────────────────────────────────
  Widget _buildAvatarStep(AppLocalizations l) {
    final user = FirebaseAuth.instance.currentUser;
    final hasPhoto = user?.photoURL != null && user!.photoURL!.isNotEmpty;

    return Column(
      key: const ValueKey('avatar'),
      children: [
        // Current preview
        _buildCurrentPreview(user, hasPhoto),
        const SizedBox(height: 16),
        Text(l.chooseProfileIcon, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          hasPhoto ? l.pickIconHintWithPhoto : l.pickIconHint,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Avatar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: _avatarIcons.length,
          itemBuilder: (_, i) {
            final selected = _selectedAvatar == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _avatarColors[i] : _avatarColors[i].withValues(alpha: 0.12),
                  border: Border.all(
                    color: selected ? _avatarColors[i] : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: _avatarColors[i].withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Icon(
                  _avatarIcons[i],
                  size: 28,
                  color: selected ? Colors.white : _avatarColors[i],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentPreview(User? user, bool hasPhoto) {
    if (_selectedAvatar >= 0) {
      return CircleAvatar(
        radius: 36,
        backgroundColor: _avatarColors[_selectedAvatar],
        child: Icon(_avatarIcons[_selectedAvatar], size: 36, color: Colors.white),
      );
    }
    if (hasPhoto) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(user!.photoURL!),
        backgroundColor: Colors.indigo.shade100,
      );
    }
    final initials = (user?.displayName ?? _nameCtrl.text)
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.indigo.shade100,
      child: Text(
        initials.isNotEmpty ? initials : 'U',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
      ),
    );
  }
}
