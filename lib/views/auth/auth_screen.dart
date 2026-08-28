import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLogin = true;

  // Consumer Controllers
  final _consumerEmailController = TextEditingController(text: 'amina@gwagwalada.com');
  final _consumerPasswordController = TextEditingController(text: 'password123');
  final _consumerNameController = TextEditingController();
  final _consumerPhoneController = TextEditingController();

  // Merchant Controllers
  final _merchantEmailController = TextEditingController(text: 'merchant@gwagwalada.com');
  final _merchantPasswordController = TextEditingController(text: 'password123');
  final _merchantBusinessController = TextEditingController();
  final _merchantPhoneController = TextEditingController();
  final _merchantBankController = TextEditingController(text: 'First Bank of Nigeria');
  final _merchantAccountController = TextEditingController(text: '0123456789');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _consumerEmailController.dispose();
    _consumerPasswordController.dispose();
    _consumerNameController.dispose();
    _consumerPhoneController.dispose();
    _merchantEmailController.dispose();
    _merchantPasswordController.dispose();
    _merchantBusinessController.dispose();
    _merchantPhoneController.dispose();
    _merchantBankController.dispose();
    _merchantAccountController.dispose();
    super.dispose();
  }

  void _handleConsumerAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (_isLogin) {
      success = await auth.loginConsumer(
        _consumerEmailController.text,
        _consumerPasswordController.text,
      );
    } else {
      success = await auth.registerConsumer(
        fullName: _consumerNameController.text.trim(),
        email: _consumerEmailController.text.trim(),
        phoneNumber: _consumerPhoneController.text.trim(),
        password: _consumerPasswordController.text,
      );
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/consumer');
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  void _handleMerchantAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (_isLogin) {
      success = await auth.loginMerchant(
        _merchantEmailController.text,
        _merchantPasswordController.text,
      );
    } else {
      success = await auth.registerMerchant(
        businessName: _merchantBusinessController.text.trim(),
        email: _merchantEmailController.text.trim(),
        phoneNumber: _merchantPhoneController.text.trim(),
        password: _merchantPasswordController.text,
        bankAccountNumber: _merchantAccountController.text.trim(),
        bankName: _merchantBankController.text.trim(),
      );
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/merchant');
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF005B36), Color(0xFF008751), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Smart Retail Pay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offline QR-Based Payment System • Gwagwalada, Abuja FCT',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Demo Profiles Bar (Instant Login for Testing)
                    const Text(
                      'QUICK DEMO PROFILES (1-TAP LOGIN)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDemoChip(
                            name: 'Amina (Shopper ₦78k)',
                            role: 'Consumer',
                            color: AppTheme.primaryGreen,
                            onTap: () async {
                              await auth.selectDemoUser(1);
                              if (context.mounted) Navigator.pushReplacementNamed(context, '/consumer');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildDemoChip(
                            name: 'Emeka (Shopper ₦45k)',
                            role: 'Consumer',
                            color: AppTheme.primaryGreen,
                            onTap: () async {
                              await auth.selectDemoUser(2);
                              if (context.mounted) Navigator.pushReplacementNamed(context, '/consumer');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildDemoChip(
                            name: 'Gwagwalada Supermarket',
                            role: 'Merchant',
                            color: const Color(0xFF6366F1),
                            onTap: () async {
                              await auth.selectDemoMerchant(1);
                              if (context.mounted) Navigator.pushReplacementNamed(context, '/merchant');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildDemoChip(
                            name: 'Exit Gate Security',
                            role: 'Security',
                            color: AppTheme.accentGold,
                            onTap: () {
                              auth.switchRole(UserRole.security);
                              Navigator.pushReplacementNamed(context, '/security');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Role Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        indicator: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(text: 'Consumer'),
                          Tab(text: 'Merchant'),
                          Tab(text: 'Exit Gate'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tab View
                    SizedBox(
                      height: 380,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Consumer Form
                          _buildConsumerAuthForm(auth),

                          // Merchant Form
                          _buildMerchantAuthForm(auth),

                          // Security Form
                          _buildSecurityQuickAccess(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoChip({
    required String name,
    required String role,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color.withAlpha(40),
        child: Text(role[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
      label: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: onTap,
    );
  }

  Widget _buildConsumerAuthForm(AuthProvider auth) {
    return Column(
      children: [
        if (!_isLogin) ...[
          TextField(
            controller: _consumerNameController,
            decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. Amina Bello'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _consumerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number', hintText: '08031234567'),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _consumerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email Address', hintText: 'amina@gwagwalada.com'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _consumerPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password', hintText: '••••••••'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleConsumerAuth,
            child: auth.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isLogin ? 'Sign In as Shopper' : 'Create Consumer Account'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(_isLogin ? "Don't have an account? Register" : "Already have an account? Sign In"),
        ),
      ],
    );
  }

  Widget _buildMerchantAuthForm(AuthProvider auth) {
    return Column(
      children: [
        if (!_isLogin) ...[
          TextField(
            controller: _merchantBusinessController,
            decoration: const InputDecoration(labelText: 'Business Name', hintText: 'Gwagwalada Supermarket Ltd'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _merchantAccountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '10-Digit NUBAN Bank Account'),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _merchantEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Merchant Email', hintText: 'merchant@gwagwalada.com'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _merchantPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password', hintText: '••••••••'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleMerchantAuth,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: auth.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isLogin ? 'Sign In as Store Merchant' : 'Register Retail Store'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(_isLogin ? "New Merchant? Register Store" : "Existing Merchant? Sign In"),
        ),
      ],
    );
  }

  Widget _buildSecurityQuickAccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 54, color: AppTheme.accentGold),
          const SizedBox(height: 12),
          const Text(
            'Exit Checkpoint Officer Mode',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Access store exit gate scanner to validate shopper receipts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              auth.switchRole(UserRole.security);
              Navigator.pushReplacementNamed(context, '/security');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: Colors.black),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Open Exit Gate Scanner'),
          ),
        ],
      ),
    );
  }
}
