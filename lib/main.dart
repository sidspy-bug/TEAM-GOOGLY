import 'package:flutter/material.dart';
import 'repositories/dummy_sales_repository.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/floating_ai_assistant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

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
      home: _isLoggedIn
          ? AppShell(onLogout: () => setState(() => _isLoggedIn = false))
          : LoginScreen(onLoginSuccess: () => setState(() => _isLoggedIn = true)),
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
  final _salesRepo = DummySalesRepository();
  bool _isPremium = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.inventory_2, 'label': 'Inventory'},
    {'icon': Icons.receipt_long, 'label': 'Sales History'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;

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
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.storefront, color: Colors.indigo.shade400, size: 28),
              const SizedBox(width: 8),
              const Text('MyShop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
        ),
        const Divider(),
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
        const Divider(),
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
        const SizedBox(height: 8),
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
        title: const Text('GrowthOS', style: TextStyle(fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.account_circle, size: 28),
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') widget.onLogout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('Profile'), dense: true, contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Logout', style: TextStyle(color: Colors.red)), dense: true, contentPadding: EdgeInsets.zero)),
            ],
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
          // Main content area with floating AI assistant
          Expanded(
            child: Stack(
              children: [
                _buildPage(),
                const FloatingAiAssistant(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
