import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/shop_config.dart';
import 'services/theme_service.dart';
import 'repositories/api_sales_repository.dart';
import 'repositories/dummy_sales_repository.dart';
import 'repositories/sales_repository_facade.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/floating_ai_assistant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Firebase Analytics
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  // Load persisted shop config
  await ShopConfig.instance.load();
  // Load persisted theme preference
  await ThemeService.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();
  bool _isLoggedIn = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    // Rebuild when theme changes
    ThemeService.instance.themeMode.addListener(_onThemeChanged);
    // Listen to Firebase auth state
    _authService.authStateChanges.listen((user) async {
      // Load user-scoped config when auth state changes
      if (user != null) {
        await ShopConfig.instance.loadForUser(user.uid);
        FirebaseAnalytics.instance.logLogin(loginMethod: user.providerData.isNotEmpty ? user.providerData.first.providerId : 'unknown');
      } else {
        await ShopConfig.instance.load(); // reset to defaults
      }
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null && (user.emailVerified || !_isEmailPasswordProvider(user));
          _initializing = false;
        });
      }
    });
    // Wire 401 handler to force logout
    ApiService().onUnauthorized = _handleLogout;
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ThemeService.instance.themeMode.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) setState(() => _isLoggedIn = false);
  }

  /// Called by LoginScreen after Firebase sign-in succeeds.
  /// Loads user settings before transitioning so shop data is available.
  Future<void> _handleLoginSuccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ShopConfig.instance.loadForUser(user.uid);
    }
    if (mounted) setState(() => _isLoggedIn = true);
  }

  /// Returns true if the user signed in with email/password only.
  bool _isEmailPasswordProvider(User user) {
    return user.providerData.every((info) => info.providerId == 'password');
  }

  Widget _buildAuthedHome() {
    if (!ShopConfig.instance.onboarded) {
      return OnboardingScreen(
        onComplete: () => setState(() {}),
      );
    }
    return AppShell(onLogout: _handleLogout);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowthOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        appBarTheme: const AppBarTheme(elevation: 0),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.dark(
          primary: Colors.indigo.shade300,
          secondary: Colors.indigoAccent,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        appBarTheme: const AppBarTheme(elevation: 0),
      ),
      themeMode: ThemeService.instance.themeMode.value,
      home: _initializing
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isLoggedIn
              ? _buildAuthedHome()
              : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}

class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AppShell({super.key, required this.onLogout});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  // Use API repository backed by the backend; falls back gracefully on error
  final _apiRepo = ApiSalesRepository();
  // Keep dummy repo as fallback for when backend is unreachable
  final _dummyRepo = DummySalesRepository();
  late final SalesRepositoryFacade _salesRepo;
  bool _isPremium = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _salesRepo = SalesRepositoryFacade(_apiRepo, _dummyRepo);
  }

  static const _navItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.inventory_2, 'label': 'Inventory'},
    {'icon': Icons.receipt_long, 'label': 'Sales History'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  // Icon/color sets shared across avatar picker and display
  static const _avatarIcons = [
    Icons.storefront, Icons.shopping_bag, Icons.local_cafe,
    Icons.restaurant, Icons.local_pharmacy, Icons.build,
    Icons.local_florist, Icons.sports_esports, Icons.auto_awesome,
  ];
  static const _avatarColors = [
    Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFEF5350),
    Color(0xFFFF7043), Color(0xFF66BB6A), Color(0xFF42A5F5),
    Color(0xFFAB47BC), Color(0xFFFFCA28), Color(0xFF78909C),
  ];

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;

  /// Builds profile avatar from stored icon, Firebase photo, or initials.
  Widget _buildProfileAvatar() {
    return ValueListenableBuilder<int>(
      valueListenable: ShopConfig.instance.avatarIndex,
      builder: (_, idx, __) {
        if (idx >= 0 && idx < _avatarIcons.length) {
          return CircleAvatar(
            radius: 14,
            backgroundColor: _avatarColors[idx],
            child: Icon(_avatarIcons[idx], size: 16, color: Colors.white),
          );
        }
        final user = FirebaseAuth.instance.currentUser;
        if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
          return CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(user.photoURL!),
            backgroundColor: Colors.indigo.shade100,
          );
        }
        final initials = (user?.displayName ?? user?.email ?? 'U')
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join();
        return CircleAvatar(
          radius: 14,
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            initials.isNotEmpty ? initials : 'U',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
          ),
        );
      },
    );
  }

  /// Shows a profile dialog with avatar, name, email, edit options.
  void _showProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    final providers = <Map<String, dynamic>>[];
    for (final p in user?.providerData ?? <UserInfo>[]) {
      switch (p.providerId) {
        case 'password':
          providers.add({'name': 'Email', 'icon': Icons.email, 'color': Colors.blue});
          break;
        case 'google.com':
          providers.add({'name': 'Google', 'icon': Icons.g_mobiledata, 'color': Colors.red});
          break;
        case 'facebook.com':
          providers.add({'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2)});
          break;
        case 'phone':
          providers.add({'name': 'Phone', 'icon': Icons.phone, 'color': Colors.green});
          break;
        default:
          providers.add({'name': p.providerId, 'icon': Icons.shield, 'color': Colors.grey});
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar — use stored icon or Firebase photo
            Builder(
              builder: (_) {
                final idx = ShopConfig.instance.avatarIndex.value;
                if (idx >= 0 && idx < _avatarIcons.length) {
                  return CircleAvatar(
                    radius: 40,
                    backgroundColor: _avatarColors[idx],
                    child: Icon(_avatarIcons[idx], size: 40, color: Colors.white),
                  );
                }
                return CircleAvatar(
                  radius: 40,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  backgroundColor: Colors.indigo.shade100,
                  child: user?.photoURL == null
                      ? Text(
                          _getInitials(user),
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              user?.email ?? '',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            // Provider badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: providers.map((p) {
                final color = p['color'] as Color;
                return Chip(
                  avatar: Icon(p['icon'] as IconData, size: 16, color: color),
                  label: Text(p['name'] as String, style: const TextStyle(fontSize: 12)),
                  backgroundColor: color.withValues(alpha: 0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Edit actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Name', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditNameDialog();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Photo', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showChangePhotoDialog();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final user = FirebaseAuth.instance.currentUser;
    final ctrl = TextEditingController(text: user?.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await user?.updateDisplayName(ctrl.text.trim());
                await user?.reload();
                Navigator.pop(ctx);
                if (mounted) setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePhotoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose an icon', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _avatarIcons.length,
                itemBuilder: (_, i) {
                  final selected = ShopConfig.instance.avatarIndex.value == i;
                  return GestureDetector(
                    onTap: () async {
                      await ShopConfig.instance.setAvatarIndex(i);
                      Navigator.pop(ctx);
                      if (mounted) setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile icon updated')),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? _avatarColors[i] : _avatarColors[i].withValues(alpha: 0.15),
                        border: Border.all(
                          color: selected ? _avatarColors[i] : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Icon(_avatarIcons[i], size: 28, color: selected ? Colors.white : _avatarColors[i]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  String _getInitials(User? user) {
    final name = user?.displayName ?? user?.email ?? 'U';
    return name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(salesRepository: _salesRepo, isPremiumUser: _isPremium, onPremiumToggle: (v) => setState(() => _isPremium = v));
      case 1:
        return InventoryScreen(salesRepository: _salesRepo);
      case 2:
        return SalesHistoryScreen(salesRepository: _salesRepo);
      case 3:
        return SettingsScreen(onLogout: widget.onLogout);
      default:
        return DashboardScreen(salesRepository: _salesRepo, isPremiumUser: _isPremium, onPremiumToggle: (v) => setState(() => _isPremium = v));
    }
  }

  Widget _buildSidebarContent({bool isDrawer = false}) {
    return Column(
      children: [
        // Dynamic shop name header
        ValueListenableBuilder<String>(
          valueListenable: ShopConfig.instance.shopName,
          builder: (_, name, __) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.storefront, color: Colors.indigo.shade400, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        ...List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final selected = _selectedIndex == i;
          return Material(
            color: selected ? Colors.indigo.shade50 : Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _selectedIndex = i);
                if (isDrawer) Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 20, color: selected ? Colors.indigo : Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? Colors.indigo : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        const Divider(height: 1),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red.shade400),
                  const SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red.shade400)),
                ],
              ),
            ),
          ),
        ),
        // Sidebar footer — platform credit
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text('GrowthOS v0.1.0', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              const SizedBox(height: 2),
              Text('\u00a9 GrowthOS', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      // Mobile drawer
      drawer: isMobile
          ? Drawer(
              child: SafeArea(
                child: _buildSidebarContent(isDrawer: true),
              ),
            )
          : null,
      // Top bar
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GrowthOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Powered by GrowthOS', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
        centerTitle: true,
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : const SizedBox(),
        leadingWidth: isMobile ? 56 : 0,
        actions: [
          // Premium toggle
          GestureDetector(
            onTap: () => setState(() => _isPremium = !_isPremium),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: _isPremium ? Colors.amber.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPremium ? Icons.star : Icons.star_border,
                    size: 16,
                    color: _isPremium ? Colors.amber.shade800 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPremium ? 'Premium' : 'Basic',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isPremium ? Colors.amber.shade900 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Profile dropdown
          PopupMenuButton<String>(
            icon: _buildProfileAvatar(),
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') widget.onLogout();
              if (value == 'profile') _showProfileDialog();
              if (value == 'settings') setState(() => _selectedIndex = 3);
            },
            itemBuilder: (context) {
              final user = FirebaseAuth.instance.currentUser;
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (user?.email != null)
                        Text(user!.email!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const Divider(),
                    ],
                  ),
                ),
                const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('View Profile'), dense: true, contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'), dense: true, contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Logout', style: TextStyle(color: Colors.red)), dense: true, contentPadding: EdgeInsets.zero)),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Permanent sidebar on desktop only
          if (!isMobile) ...[
            Container(
              width: 240,
              color: Colors.white,
              child: _buildSidebarContent(),
            ),
            VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
          ],
          // Main content area with floating AI assistant (Dashboard only)
          Expanded(
            child: Stack(
              children: [
                _buildPage(),
                if (_selectedIndex == 0) const FloatingAiAssistant(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
