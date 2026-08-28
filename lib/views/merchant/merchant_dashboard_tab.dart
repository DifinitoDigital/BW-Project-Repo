import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/digital_receipt_dialog.dart';
import '../../widgets/role_switcher_modal.dart';

class MerchantDashboardTab extends StatefulWidget {
  final Function(int) onTabChange;

  const MerchantDashboardTab({super.key, required this.onTabChange});

  @override
  State<MerchantDashboardTab> createState() => _MerchantDashboardTabState();
}

class _MerchantDashboardTabState extends State<MerchantDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentMerchant != null) {
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).loadMerchantTransactions(auth.currentMerchant!.merchantId!);
        Provider.of<InventoryProvider>(
          context,
          listen: false,
        ).loadProducts(merchantId: auth.currentMerchant!.merchantId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);

    final merchant = auth.currentMerchant;
    final lowStock = invProvider.lowStockProducts;
    final recentTxns = txProvider.merchantTransactions.take(5).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (merchant != null) {
            await txProvider.loadMerchantTransactions(merchant.merchantId!);
            await invProvider.loadProducts(merchantId: merchant.merchantId!);
          }
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Merchant Info Header
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
                          backgroundColor: AppTheme.accentGold.withAlpha(30),
                          child: const Icon(
                            Icons.store,
                            color: AppTheme.accentGold,
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
                                      merchant?.businessName ?? 'Gwagwalada Supermarket',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                                ],
                              ),
                              Text(
                                'Merchant ID: MRCH-${merchant?.merchantId ?? 1} • ${merchant?.bankName ?? 'First Bank'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppTheme.primaryGreen,
                        size: 26,
                      ),
                      tooltip: 'Switch to Shopper / Role',
                    ),
                    IconButton(
                      onPressed: () {
                        auth.switchRole(UserRole.security);
                        Navigator.pushReplacementNamed(context, '/security');
                      },
                      icon: const Icon(
                        Icons.security,
                        color: AppTheme.accentGold,
                      ),
                      tooltip: 'Exit Gate Verifier',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Revenue Card
            CustomCard(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
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
                      const Text(
                        'TOTAL SALES REVENUE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LIVE OFFLINE POS',
                          style: TextStyle(
                            color: AppTheme.primaryGreenLight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(txProvider.merchantTotalRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today: ${CurrencyFormatter.format(txProvider.merchantTodayRevenue)}',
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${txProvider.merchantTotalSalesCount} Completed Sales',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onTabChange(2), // POS tab
                          icon: const Icon(Icons.qr_code_scanner, size: 16),
                          label: const Text('POS Terminal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              widget.onTabChange(3), // Settlement tab
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.account_balance, size: 16),
                          label: const Text('Bank Transfer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Low Stock Alert (if any)
            if (lowStock.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.warningColor.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${lowStock.length} product(s) are low in stock (below 10 units).',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onTabChange(1), // Inventory tab
                      child: const Text('Restock'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Management Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.inventory_2,
                    label: 'Product QR Studio',
                    sub: '${invProvider.allProductsRaw.length} Items Listed',
                    color: AppTheme.primaryGreen,
                    onTap: () => widget.onTabChange(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.analytics,
                    label: 'Sales Analytics',
                    sub: 'Performance & Trends',
                    color: const Color(0xFF6366F1),
                    onTap: () => widget.onTabChange(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Store Sales Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Supermarket Transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${txProvider.merchantTransactions.length} Total',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (recentTxns.isEmpty)
              CustomCard(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text('No store transactions recorded yet.'),
                ),
              )
            else
              ...recentTxns.map((tx) {
                final isSettlement = tx.transactionType == 'Bank Settlement';
                return CustomCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  onTap: () => DigitalReceiptDialog.show(
                    context,
                    tx,
                    storeName:
                        merchant?.businessName ?? 'Gwagwalada Supermarket Ltd',
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSettlement
                            ? const Color(0xFF6366F1).withAlpha(30)
                            : AppTheme.primaryGreen.withAlpha(30),
                        child: Icon(
                          isSettlement
                              ? Icons.account_balance
                              : Icons.point_of_sale,
                          color: isSettlement
                              ? const Color(0xFF6366F1)
                              : AppTheme.primaryGreen,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (tx.itemsSummary.isNotEmpty)
                              Text(
                                tx.itemsSummary,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              CurrencyFormatter.formatShortDate(tx.dateTime),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(tx.amount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSettlement
                                  ? const Color(0xFF6366F1)
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.status,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
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

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(15)
                : Colors.black.withAlpha(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
