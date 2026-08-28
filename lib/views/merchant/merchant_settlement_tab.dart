import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/digital_receipt_dialog.dart';

class MerchantSettlementTab extends StatefulWidget {
  const MerchantSettlementTab({super.key});

  @override
  State<MerchantSettlementTab> createState() => _MerchantSettlementTabState();
}

class _MerchantSettlementTabState extends State<MerchantSettlementTab> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  String _selectedBank = 'First Bank of Nigeria';

  final List<String> _nigerianBanks = [
    'First Bank of Nigeria',
    'Zenith Bank',
    'Guaranty Trust Bank (GTBank)',
    'Access Bank',
    'United Bank for Africa (UBA)',
    'Kuda Microfinance Bank',
    'OPay Digital Services',
    'Moniepoint Microfinance Bank',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _accountNumberController.text = auth.currentMerchant?.bankAccountNumber ?? '0123456789';
    _selectedBank = auth.currentMerchant?.bankName ?? 'First Bank of Nigeria';
  }

  void _handleSettlement() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    final txn = await txProvider.settleToBank(
      merchantId: auth.currentMerchant?.merchantId ?? 1,
      amount: amount,
      bankName: _selectedBank,
      bankAccount: _accountNumberController.text.trim(),
    );

    if (txn != null && mounted) {
      _amountController.clear();
      DigitalReceiptDialog.show(
        context,
        txn,
        storeName: auth.currentMerchant?.businessName ?? 'Gwagwalada Supermarket Ltd',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    final settlements = txProvider.merchantTransactions
        .where((t) => t.transactionType == 'Bank Settlement')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Settlement & Transfers'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Store Balance Card
          CustomCard(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AVAILABLE STORE BALANCE',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(txProvider.merchantTotalRevenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Linked: ${auth.currentMerchant?.bankName ?? 'First Bank'} (${auth.currentMerchant?.bankAccountNumber ?? '0123456789'})',
                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transfer Form
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRANSFER REVENUE TO BANK',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedBank,
                  items: _nigerianBanks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                  decoration: const InputDecoration(labelText: 'Destination Bank'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '10-Digit NUBAN Account Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Transfer (₦)',
                    prefixText: '₦ ',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleSettlement,
                    icon: const Icon(Icons.account_balance, size: 18),
                    label: const Text('Process Instant Bank Settlement'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settlement History
          const Text(
            'Previous Bank Settlements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (settlements.isEmpty)
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: Text('No bank settlements processed yet.'),
              ),
            )
          else
            ...settlements.map((tx) {
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 8),
                onTap: () => DigitalReceiptDialog.show(context, tx),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF4338CA),
                    child: Icon(Icons.account_balance, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    CurrencyFormatter.format(tx.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${tx.itemsSummary}\n${CurrencyFormatter.formatDate(tx.dateTime)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            }),
        ],
      ),
    );
  }
}
