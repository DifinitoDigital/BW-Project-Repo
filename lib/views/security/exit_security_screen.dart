import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/interactive_scanner_modal.dart';
import '../../widgets/digital_receipt_dialog.dart';
import '../../widgets/role_switcher_modal.dart';

class ExitSecurityScreen extends StatefulWidget {
  const ExitSecurityScreen({super.key});

  @override
  State<ExitSecurityScreen> createState() => _ExitSecurityScreenState();
}

class _ExitSecurityScreenState extends State<ExitSecurityScreen> {
  final TextEditingController _receiptCodeController = TextEditingController();

  void _triggerScan() async {
    final scanned = await InteractiveScannerModal.show(
      context,
      title: 'Scan Customer Exit Receipt',
      prompt: 'Point at customer digital receipt QR code at exit door',
      scanTarget: 'receipt',
    );

    if (scanned != null && mounted) {
      _receiptCodeController.text = scanned;
      final sec = Provider.of<SecurityProvider>(context, listen: false);
      await sec.verifyReceipt(scanned);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sec = Provider.of<SecurityProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Exit Gate Verifier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Switch Role',
            onPressed: () => RoleSwitcherModal.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Officer Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.accentGold.withAlpha(80)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security, color: AppTheme.accentGold, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exit Gate Checkpoint Officer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gwagwalada Supermarket • Anti-Theft & Cart Validation',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scan Trigger & Manual Input
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SCAN EXIT RECEIPT QR CODE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _triggerScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 22),
                    label: const Text('Launch Exit Scanner (Camera / Test Codes)'),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _receiptCodeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Receipt or TXN Ref code...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final text = _receiptCodeController.text.trim();
                        if (text.isNotEmpty) {
                          sec.verifyReceipt(text);
                        }
                      },
                      child: const Text('Verify'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Verification Status Banner
          if (sec.status != VerificationStatus.idle) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _getStatusBgColor(sec.status),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _getStatusBorderColor(sec.status), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getStatusIcon(sec.status), color: _getStatusTextColor(sec.status), size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getStatusTitle(sec.status),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _getStatusTextColor(sec.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sec.statusMessage,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  // If transaction found, show purchased item list
                  if (sec.verifiedTransaction != null) ...[
                    const Divider(height: 24),
                    const Text(
                      'VERIFIED BASKET ITEMS:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withAlpha(60) : Colors.white.withAlpha(160),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sec.verifiedTransaction!.itemsSummary,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount: ${CurrencyFormatter.format(sec.verifiedTransaction!.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () => DigitalReceiptDialog.show(context, sec.verifiedTransaction!),
                          child: const Text('View Full Receipt'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Verified Exit Log Today
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exit Clearances Recorded Today',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${sec.verifiedHistory.length} Cleared',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (sec.verifiedHistory.isEmpty)
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text('No customers verified through this checkpoint yet.'),
              ),
            )
          else
            ...sec.verifiedHistory.map((tx) {
              return CustomCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                onTap: () => DigitalReceiptDialog.show(context, tx),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      child: Icon(Icons.verified, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.receiptCode,
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Paid: ${CurrencyFormatter.format(tx.amount)} • ${tx.itemsSummary}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CLEARED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getStatusBgColor(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.approved:
        return AppTheme.primaryGreen.withAlpha(20);
      case VerificationStatus.alreadyVerified:
        return AppTheme.warningColor.withAlpha(25);
      case VerificationStatus.invalid:
      case VerificationStatus.error:
        return AppTheme.dangerColor.withAlpha(20);
      default:
        return Colors.grey.withAlpha(20);
    }
  }

  Color _getStatusBorderColor(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.approved:
        return AppTheme.primaryGreen;
      case VerificationStatus.alreadyVerified:
        return AppTheme.warningColor;
      case VerificationStatus.invalid:
      case VerificationStatus.error:
        return AppTheme.dangerColor;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusTextColor(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.approved:
        return AppTheme.primaryGreen;
      case VerificationStatus.alreadyVerified:
        return AppTheme.warningColor;
      case VerificationStatus.invalid:
      case VerificationStatus.error:
        return AppTheme.dangerColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.approved:
        return Icons.check_circle;
      case VerificationStatus.alreadyVerified:
        return Icons.warning_amber_rounded;
      case VerificationStatus.invalid:
      case VerificationStatus.error:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusTitle(VerificationStatus s) {
    switch (s) {
      case VerificationStatus.approved:
        return 'EXIT GRANTED: PAYMENT VERIFIED';
      case VerificationStatus.alreadyVerified:
        return 'WARNING: ALREADY SCANNED / DUPLICATE';
      case VerificationStatus.invalid:
        return 'INVALID / UNPAID RECEIPT';
      case VerificationStatus.error:
        return 'VERIFICATION ERROR';
      default:
        return 'VERIFYING';
    }
  }
}
