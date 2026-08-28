import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/interactive_scanner_modal.dart';
import '../../widgets/digital_receipt_dialog.dart';
import '../../widgets/role_switcher_modal.dart';

class ConsumerHomeTab extends StatefulWidget {
  final Function(int) onTabChange;

  const ConsumerHomeTab({super.key, required this.onTabChange});

  @override
  State<ConsumerHomeTab> createState() => _ConsumerHomeTabState();
}

class _ConsumerHomeTabState extends State<ConsumerHomeTab> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<WalletProvider>(context, listen: false).loadWallet(auth.currentUser!.userId!);
        Provider.of<TransactionProvider>(context, listen: false).loadUserTransactions(auth.currentUser!.userId!);
        Provider.of<CartProvider>(context, listen: false).loadCart(auth.currentUser!.userId!);
      }
    });
  }

  void _showFundWalletModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final amountController = TextEditingController(text: '10000');
    String selectedMethod = 'Access Bank Mastercard (•••• 4821)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preload / Fund Wallet (Offline)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Simulate instant wallet top-up using saved cards or bank transfer.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SELECT AMOUNT (₦)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [2000, 5000, 10000, 25000, 50000].map((amt) {
                      final isSelected = amountController.text == amt.toString();
                      return ChoiceChip(
                        label: Text('₦${amt ~/ 1000}k'),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          setModalState(() {
                            amountController.text = amt.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.money, color: AppTheme.primaryGreen),
                      labelText: 'Custom Amount (₦)',
                      hintText: 'Enter amount to preload',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PAYMENT METHOD',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedMethod,
                    items: [
                      'Access Bank Mastercard (•••• 4821)',
                      'GTBank Visa Card (•••• 9014)',
                      'Zenith Bank Direct Transfer',
                      'First Bank USSD / Instant Cash',
                    ].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedMethod = val);
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amt <= 0) return;

                        final messenger = ScaffoldMessenger.of(context);
                        final txProvider = Provider.of<TransactionProvider>(context, listen: false);

                        Navigator.pop(context);
                        final success = await wallet.fundWallet(
                          userId: auth.currentUser!.userId!,
                          amount: amt,
                          fundingMethod: selectedMethod,
                        );

                        if (success) {
                          txProvider.loadUserTransactions(auth.currentUser!.userId!);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Successfully loaded ${CurrencyFormatter.format(amt)} into your wallet!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                      },
                      child: const Text('Confirm Top-Up (Instant Offline)'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAirtimeModal() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final phoneController = TextEditingController(text: auth.currentUser?.phoneNumber ?? '08031234567');
    final amountController = TextEditingController(text: '1000');
    String selectedNetwork = 'MTN Nigeria';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Prepaid Airtime / Data Recharge',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Instant mobile recharge debited from your offline wallet balance.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedNetwork,
                  items: ['MTN Nigeria', 'Airtel Nigeria', 'Glo Mobile', '9mobile']
                      .map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedNetwork = val);
                  },
                  decoration: const InputDecoration(labelText: 'Network Provider'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₦)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (amt <= 0) return;

                      final messenger = ScaffoldMessenger.of(context);
                      final txProvider = Provider.of<TransactionProvider>(context, listen: false);

                      Navigator.pop(context);
                      final success = await wallet.rechargePrepaid(
                        userId: auth.currentUser!.userId!,
                        phoneNumber: phoneController.text.trim(),
                        network: selectedNetwork,
                        amount: amt,
                      );

                      if (success) {
                        txProvider.loadUserTransactions(auth.currentUser!.userId!);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Recharge of ${CurrencyFormatter.format(amt)} successful!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Insufficient balance for airtime recharge.'),
                            backgroundColor: AppTheme.dangerColor,
                          ),
                        );
                      }
                    },
                    child: const Text('Recharge Now'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final wallet = Provider.of<WalletProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = auth.currentUser;
    final recentTxns = txProvider.userTransactions.take(4).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await wallet.loadWallet(user.userId!);
            await txProvider.loadUserTransactions(user.userId!);
            await cart.loadCart(user.userId!);
          }
        },
        child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => RoleSwitcherModal.show(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryGreen.withAlpha(40),
                        child: Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'U',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Hello, ${user?.fullName.split(' ').first ?? 'Shopper'} 👋',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.successColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text(
                                    'Gwagwalada Supermarket Hub (Offline)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => RoleSwitcherModal.show(context),
                    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF6366F1), size: 26),
                    tooltip: 'Switch to Merchant / Role',
                  ),
                  IconButton(
                    onPressed: () => widget.onTabChange(3), // My QR
                    icon: const Icon(Icons.qr_code, color: AppTheme.primaryGreen),
                    tooltip: 'My Payment QR',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Wallet Balance Card (Fintech Gradient)
          CustomCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF005B36), Color(0xFF008751), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'PRELOADED WALLET BALANCE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isBalanceVisible
                      ? CurrencyFormatter.format(wallet.balance)
                      : '₦ ••••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Account ID: GWAG-USR-${user?.userId ?? 1} • Auto-Sync Ready',
                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showFundWalletModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryGreenDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_circle, size: 18),
                        label: const Text('Fund Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onTabChange(2), // Product Scanner
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Scan Shelf Item', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action Hub
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.shopping_cart,
                  label: 'Smart Cart',
                  badge: cart.totalItemCount > 0 ? '${cart.totalItemCount}' : null,
                  color: AppTheme.primaryGreen,
                  onTap: () => widget.onTabChange(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.qr_code_2,
                  label: 'Scan Shelf QR',
                  color: const Color(0xFF0284C7),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final scanned = await InteractiveScannerModal.show(
                      context,
                      title: 'Scan Supermarket Item',
                      prompt: 'Scan item QR code from shelf or basket',
                      scanTarget: 'product',
                    );
                    if (scanned != null && user != null) {
                      final product = await cart.scanAndAddToCart(
                        userId: user.userId!,
                        qrCode: scanned,
                      );
                      if (product != null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Added "${product.productName}" to Smart Cart!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.phone_android,
                  label: 'Airtime',
                  color: AppTheme.accentGold,
                  onTap: _showAirtimeModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.receipt_long,
                  label: 'History',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => widget.onTabChange(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Smart Cart Banner (if items exist)
          if (cart.items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentGold, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag, color: AppTheme.accentGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping in Progress (${cart.totalItemCount} items)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Running Total: ${CurrencyFormatter.format(cart.totalAmount)}',
                          style: const TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onTabChange(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Recent Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => widget.onTabChange(4),
                child: const Text('See All'),
              ),
            ],
          ),

          if (recentTxns.isEmpty)
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'No transactions yet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Scan a shelf item or fund your wallet to begin shopping.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTxns.map((tx) {
              final isTopUp = tx.transactionType == 'Wallet Load';
              return CustomCard(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () {
                  DigitalReceiptDialog.show(context, tx);
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isTopUp
                          ? AppTheme.successColor.withAlpha(30)
                          : AppTheme.primaryGreen.withAlpha(30),
                      child: Icon(
                        isTopUp ? Icons.arrow_downward : Icons.shopping_basket,
                        color: isTopUp ? AppTheme.successColor : AppTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.transactionType,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            CurrencyFormatter.formatShortDate(tx.dateTime),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isTopUp ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isTopUp ? AppTheme.successColor : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        if (tx.transactionType == 'Cart Self-Checkout')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tx.isExitVerified
                                  ? AppTheme.primaryGreen.withAlpha(30)
                                  : AppTheme.accentGold.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tx.isExitVerified ? 'Exit Verified' : 'Exit Pass QR',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: tx.isExitVerified
                                    ? AppTheme.primaryGreen
                                    : AppTheme.accentGold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    ),
  );
}

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.dangerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
