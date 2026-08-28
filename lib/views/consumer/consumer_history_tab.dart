import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/digital_receipt_dialog.dart';

class ConsumerHistoryTab extends StatefulWidget {
  const ConsumerHistoryTab({super.key});

  @override
  State<ConsumerHistoryTab> createState() => _ConsumerHistoryTabState();
}

class _ConsumerHistoryTabState extends State<ConsumerHistoryTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allTxns = txProvider.userTransactions;
    final filteredTxns = allTxns.where((t) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Shopping') return t.transactionType == 'Cart Self-Checkout' || t.transactionType == 'Direct Merchant Pay';
      if (_selectedFilter == 'Top-Up') return t.transactionType == 'Wallet Load';
      if (_selectedFilter == 'Airtime') return t.transactionType == 'Prepaid Recharge';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History & Receipts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total Spend Card
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL SPENT IN GWAGWALADA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(txProvider.consumerTotalSpent),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${allTxns.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text('Txns', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Shopping', 'Top-Up', 'Airtime'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen.withAlpha(40),
                    checkmarkColor: AppTheme.primaryGreen,
                    onSelected: (val) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (filteredTxns.isEmpty)
            CustomCard(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No Transactions Found', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'No transactions match the "$_selectedFilter" filter.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredTxns.map((tx) {
              final isTopUp = tx.transactionType == 'Wallet Load';
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                onTap: () => DigitalReceiptDialog.show(context, tx),
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
                          if (tx.itemsSummary.isNotEmpty)
                            Text(
                              tx.itemsSummary,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            CurrencyFormatter.formatDate(tx.dateTime),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'View Receipt',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
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
    );
  }
}
