import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';
import 'consumer_home_tab.dart';
import 'smart_cart_tab.dart';
import 'product_scanner_tab.dart';
import 'consumer_qr_tab.dart';
import 'consumer_history_tab.dart';
import '../../widgets/role_switcher_modal.dart';

class ConsumerMainScreen extends StatefulWidget {
  const ConsumerMainScreen({super.key});

  @override
  State<ConsumerMainScreen> createState() => _ConsumerMainScreenState();
}

class _ConsumerMainScreenState extends State<ConsumerMainScreen> {
  int _currentIndex = 0;

  void _onTabSelect(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> tabs = [
      ConsumerHomeTab(onTabChange: _onTabSelect),
      SmartCartTab(onNavigate: _onTabSelect),
      ProductScannerTab(onNavigate: _onTabSelect),
      const ConsumerQrTab(),
      const ConsumerHistoryTab(),
    ];

    return Scaffold(
      drawer: _buildAppDrawer(context, auth),
      body: tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelect,
        indicatorColor: AppTheme.primaryGreen.withAlpha(40),
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreen),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.totalItemCount > 0,
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cart.totalItemCount > 0,
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_cart, color: AppTheme.primaryGreen),
            ),
            label: 'Smart Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen),
            label: 'Scan Shelf',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code),
            selectedIcon: Icon(Icons.qr_code, color: AppTheme.primaryGreen),
            label: 'My QR',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF005B36), Color(0xFF008751)],
              ),
            ),
            accountName: Text(
              user?.fullName ?? 'Amina Bello',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(user?.email ?? 'amina@gwagwalada.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.switch_account, color: AppTheme.accentGold),
            title: const Text('Switch Role / Demo Profile'),
            subtitle: const Text('Merchant, Security Officer, or Shopper'),
            onTap: () {
              Navigator.pop(context);
              RoleSwitcherModal.show(context);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Gwagwalada Retail System Information',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.primaryGreen),
            title: const Text('About Smart Retail Pay'),
            subtitle: const Text('Offline QR Mobile Wallet for Gwagwalada FCT'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: AppTheme.primaryGreen),
            title: const Text('Exit Gate Security Check'),
            subtitle: const Text('Launch exit pass receipt validator'),
            onTap: () {
              Navigator.pop(context);
              auth.switchRole(UserRole.security);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.dangerColor),
            title: const Text('Sign Out'),
            onTap: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text('About System'),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Design and Implementation of a QR Code-Based Smart Retail Payment System',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              'Case Study: Retail Environment of Gwagwalada, Abuja Federal Capital Territory (FCT), Nigeria.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Text(
              '• 100% Offline SQLite Architecture\n• Live Shelf QR Scanning & Running Cart Total\n• Preloaded Wallet Instant Self-Checkout\n• Exit Gate Digital Receipt Verification\n• Merchant Inventory & Sales Analytics',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
