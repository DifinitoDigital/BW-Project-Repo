import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/qr_view_card.dart';
import '../../widgets/digital_receipt_dialog.dart';

class ConsumerQrTab extends StatelessWidget {
  const ConsumerQrTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final wallet = Provider.of<WalletProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    final user = auth.currentUser;
    final userQrPayload = 'USER-${user?.userId ?? 1}';

    final exitPasses = txProvider.userTransactions
        .where((t) => t.transactionType == 'Cart Self-Checkout')
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payment & Exit Passes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Personal Payment QR
          QrViewCard(
            qrData: userQrPayload,
            title: user?.fullName ?? 'Consumer Payment QR',
            subtitle: 'Show this QR code to any supermarket cashier/merchant to pay directly.',
            badgeText: 'OFFLINE CONSUMER WALLET',
            size: 180,
          ),
          const SizedBox(height: 16),

          // Account summary box
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Available Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(wallet.balance),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.grey.withAlpha(50)),
                Column(
                  children: [
                    const Text('Registered Phone', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      user?.phoneNumber ?? '08031234567',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Exit Pass History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Store Exit Passes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${exitPasses.length} Passes',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (exitPasses.isEmpty)
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.qr_code_2, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No Exit Passes Found', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Self-checkout receipts will appear here as exit passes.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...exitPasses.map((tx) {
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => DigitalReceiptDialog.show(context, tx),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: tx.isExitVerified
                        ? AppTheme.primaryGreen.withAlpha(30)
                        : AppTheme.accentGold.withAlpha(30),
                    child: Icon(
                      tx.isExitVerified ? Icons.verified : Icons.qr_code,
                      color: tx.isExitVerified ? AppTheme.primaryGreen : AppTheme.accentGold,
                    ),
                  ),
                  title: Text(
                    tx.receiptCode,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${CurrencyFormatter.format(tx.amount)} • ${CurrencyFormatter.formatShortDate(tx.dateTime)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tx.isExitVerified
                          ? AppTheme.primaryGreen.withAlpha(20)
                          : AppTheme.accentGold.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.isExitVerified ? 'Verified' : 'Show Exit QR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tx.isExitVerified ? AppTheme.primaryGreen : AppTheme.accentGold,
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
