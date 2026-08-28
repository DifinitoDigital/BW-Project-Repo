import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'merchant_dashboard_tab.dart';
import 'merchant_inventory_tab.dart';
import 'merchant_pos_tab.dart';
import 'merchant_settlement_tab.dart';
import 'merchant_analytics_tab.dart';
import '../../widgets/role_switcher_modal.dart';

class MerchantMainScreen extends StatefulWidget {
  const MerchantMainScreen({super.key});

  @override
  State<MerchantMainScreen> createState() => _MerchantMainScreenState();
}

class _MerchantMainScreenState extends State<MerchantMainScreen> {
  int _currentIndex = 0;

  void _onTabSelect(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> tabs = [
      MerchantDashboardTab(onTabChange: _onTabSelect),
      const MerchantInventoryTab(),
      const MerchantPosTab(),
      const MerchantSettlementTab(),
      const MerchantAnalyticsTab(),
    ];

    return Scaffold(
      drawer: _buildMerchantDrawer(context, auth),
      body: tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelect,
        indicatorColor: AppTheme.primaryGreen.withAlpha(40),
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreen),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppTheme.primaryGreen),
            label: 'QR Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale, color: AppTheme.primaryGreen),
            label: 'POS Collect',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance, color: AppTheme.primaryGreen),
            label: 'Settlement',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primaryGreen),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantDrawer(BuildContext context, AuthProvider auth) {
    final merchant = auth.currentMerchant;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
            ),
            accountName: Text(
              merchant?.businessName ?? 'Gwagwalada Supermarket Ltd',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            accountEmail: Text('${merchant?.email ?? 'merchant@gwagwalada.com'} • ${merchant?.bankName ?? 'First Bank'}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppTheme.accentGold,
              child: Icon(Icons.store, color: Colors.black, size: 28),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.switch_account, color: AppTheme.accentGold),
            title: const Text('Switch Role / Demo Profile'),
            subtitle: const Text('Consumer, Merchant, or Security Officer'),
            onTap: () {
              Navigator.pop(context);
              RoleSwitcherModal.show(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: AppTheme.primaryGreen),
            title: const Text('Supermarket Exit Gate Verifier'),
            subtitle: const Text('Scan customer exit receipts at door'),
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
}
