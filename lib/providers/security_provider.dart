import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../models/transaction_model.dart';

enum VerificationStatus {
  idle,
  verifying,
  approved,
  alreadyVerified,
  invalid,
  error,
}

class SecurityProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  VerificationStatus _status = VerificationStatus.idle;
  TransactionModel? _verifiedTransaction;
  String _statusMessage = 'Point camera or enter receipt code to verify';
  final List<TransactionModel> _verifiedHistory = [];

  VerificationStatus get status => _status;
  TransactionModel? get verifiedTransaction => _verifiedTransaction;
  String get statusMessage => _statusMessage;
  List<TransactionModel> get verifiedHistory => _verifiedHistory;

  void reset() {
    _status = VerificationStatus.idle;
    _verifiedTransaction = null;
    _statusMessage = 'Point camera or enter receipt code to verify';
    notifyListeners();
  }

  Future<void> verifyReceipt(String receiptOrRefCode) async {
    final cleanCode = receiptOrRefCode.trim();
    if (cleanCode.isEmpty) return;

    _status = VerificationStatus.verifying;
    _statusMessage = 'Verifying receipt against offline store ledger...';
    notifyListeners();

    try {
      TransactionModel? txn;
      if (cleanCode.startsWith('RCP-')) {
        txn = await _dbHelper.getTransactionByReceiptCode(cleanCode);
      } else if (cleanCode.startsWith('TXN-')) {
        txn = await _dbHelper.getTransactionByRef(cleanCode);
      } else {
        // Try both
        txn = await _dbHelper.getTransactionByReceiptCode(cleanCode);
        txn ??= await _dbHelper.getTransactionByRef(cleanCode);
      }

      if (txn == null) {
        _status = VerificationStatus.invalid;
        _verifiedTransaction = null;
        _statusMessage =
            'INVALID RECEIPT: No matching paid transaction found in database.';
        notifyListeners();
        return;
      }

      if (txn.status != 'Successful') {
        _status = VerificationStatus.invalid;
        _verifiedTransaction = txn;
        _statusMessage =
            'PAYMENT FAILED: This transaction was not completed successfully.';
        notifyListeners();
        return;
      }

      if (txn.isExitVerified) {
        _status = VerificationStatus.alreadyVerified;
        _verifiedTransaction = txn;
        _statusMessage =
            'WARNING: This receipt was ALREADY VERIFIED on ${txn.verifiedAt != null ? txn.verifiedAt.toString().substring(0, 16) : 'earlier today'}. Potential duplicate exit attempt!';
        notifyListeners();
        return;
      }

      // Mark as verified
      await _dbHelper.markTransactionExitVerified(txn.transactionRef);
      final updatedTxn = txn.copyWith(
        isExitVerified: true,
        verifiedAt: DateTime.now(),
      );

      _status = VerificationStatus.approved;
      _verifiedTransaction = updatedTxn;
      _statusMessage =
          'VERIFICATION SUCCESSFUL: Paid in full. Customer is cleared for exit.';
      _verifiedHistory.insert(0, updatedTxn);
      notifyListeners();
    } catch (e) {
      _status = VerificationStatus.error;
      _statusMessage = 'Verification error: ${e.toString()}';
      notifyListeners();
    }
  }
}
