import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/seed_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/interactive_scanner_modal.dart';
import '../../widgets/digital_receipt_dialog.dart';

class MerchantPosTab extends StatefulWidget {
  const MerchantPosTab({super.key});

  @override
  State<MerchantPosTab> createState() => _MerchantPosTabState();
}

class _MerchantPosTabState extends State<MerchantPosTab> {
  int? _selectedUserId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _itemsDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default to first customer for instant POS testing
    _selectedUserId = SeedData.initialUsers.first.userId;
  }

  void _triggerScanCustomer() async {
    final scanned = await InteractiveScannerModal.show(
      context,
      title: 'Scan Customer QR Code',
      prompt: 'Point at customer phone wallet QR code',
      scanTarget: 'consumer',
    );

    if (scanned != null && mounted) {
      // Extract user id (e.g. USER-1)
      final idStr = scanned.replaceAll(RegExp(r'[^0-9]'), '');
      final id = int.tryParse(idStr) ?? 1;

      final matched = SeedData.initialUsers.firstWhere(
        (u) => u.userId == id,
        orElse: () => SeedData.initialUsers.first,
      );

      setState(() {
        _selectedUserId = matched.userId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer "${matched.fullName}" verified for payment!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _processPosCharge() async {
    final selectedCustomer = SeedData.initialUsers.firstWhere(
      (u) => u.userId == _selectedUserId,
      orElse: () => SeedData.initialUsers.first,
    );

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid charge amount.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    final txn = await txProvider.directMerchantCharge(
      merchantId: auth.currentMerchant?.merchantId ?? 1,
      consumerUserId: selectedCustomer.userId!,
      amount: amount,
      itemsDescription: _itemsDescController.text.trim(),
      walletProvider: wallet,
    );

    if (txn != null && mounted) {
      _amountController.clear();
      _itemsDescController.clear();
      DigitalReceiptDialog.show(
        context,
        txn,
        storeName: auth.currentMerchant?.businessName ?? 'Gwagwalada Supermarket Ltd',
      );
    } else if (mounted && txProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txProvider.errorMessage!),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant POS Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen),
            tooltip: 'Scan Customer QR',
            onPressed: _triggerScanCustomer,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer Selector / Scan card
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CUSTOMER WALLET',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    TextButton.icon(
                      onPressed: _triggerScanCustomer,
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Scan QR'),
                    ),
                  ],
                ),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _selectedUserId,
                  items: SeedData.initialUsers.map((u) {
                    return DropdownMenuItem<int>(
                      value: u.userId,
                      child: Text(
                        '${u.fullName} (${u.phoneNumber})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) setState(() => _selectedUserId = id);
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Charge Input Box
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHARGE AMOUNT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: '₦ ',
                    prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Amount Buttons
                Wrap(
                  spacing: 8,
                  children: [1000, 2500, 5000, 10000, 20000].map((amt) {
                    return ActionChip(
                      label: Text('₦${amt ~/ 1000}k'),
                      onPressed: () {
                        setState(() {
                          _amountController.text = amt.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _itemsDescController,
                  decoration: const InputDecoration(
                    labelText: 'Items / Sale Description (Optional)',
                    hintText: 'e.g. 2x Peak Milk, 1x Indomie carton',
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _processPosCharge,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Charge Offline Customer Wallet'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // POS Security Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Offline encrypted transaction. Instant debit from customer wallet with cryptographic exit receipt generated.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
