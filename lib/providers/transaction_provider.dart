import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/db_helper.dart';
import '../models/transaction_model.dart';
import 'wallet_provider.dart';

class TransactionProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  final Uuid _uuid = const Uuid();

  List<TransactionModel> _userTransactions = [];
  List<TransactionModel> _merchantTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get userTransactions => _userTransactions;
  List<TransactionModel> get merchantTransactions => _merchantTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Merchant Analytics
  double get merchantTotalRevenue {
    return _merchantTransactions
        .where((t) => (t.transactionType == 'Cart Self-Checkout' || t.transactionType == 'Direct Merchant Pay') && t.status == 'Successful')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get merchantTodayRevenue {
    final now = DateTime.now();
    return _merchantTransactions
        .where((t) =>
            (t.transactionType == 'Cart Self-Checkout' || t.transactionType == 'Direct Merchant Pay') &&
            t.status == 'Successful' &&
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month &&
            t.dateTime.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  int get merchantTotalSalesCount {
    return _merchantTransactions
        .where((t) => (t.transactionType == 'Cart Self-Checkout' || t.transactionType == 'Direct Merchant Pay') && t.status == 'Successful')
        .length;
  }

  // Consumer Analytics: Spending breakdown
  double get consumerTotalSpent {
    return _userTransactions
        .where((t) => (t.transactionType == 'Cart Self-Checkout' || t.transactionType == 'Direct Merchant Pay' || t.transactionType == 'Prepaid Recharge') && t.status == 'Successful')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> loadUserTransactions(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userTransactions = await _dbHelper.getTransactionsForUser(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMerchantTransactions(int merchantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _merchantTransactions = await _dbHelper.getTransactionsForMerchant(merchantId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Merchant POS Collection from customer QR
  Future<TransactionModel?> directMerchantCharge({
    required int merchantId,
    required int consumerUserId,
    required double amount,
    required String itemsDescription,
    required WalletProvider walletProvider,
  }) async {
    if (amount <= 0) {
      _errorMessage = 'Invalid charge amount';
      notifyListeners();
      return null;
    }

    if (walletProvider.balance < amount) {
      _errorMessage = 'Customer has insufficient wallet balance';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final deducted = await walletProvider.deductAmount(consumerUserId, amount);
      if (!deducted) {
        _errorMessage = 'Could not deduct funds from customer';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final txnRef = 'TXN-POS-${_uuid.v4().substring(0, 8).toUpperCase()}';
      final receiptCode = 'RCP-POS-${_uuid.v4().substring(0, 8).toUpperCase()}';

      final txn = TransactionModel(
        transactionRef: txnRef,
        userId: consumerUserId,
        merchantId: merchantId,
        amount: amount,
        transactionType: 'Direct Merchant Pay',
        status: 'Successful',
        dateTime: DateTime.now(),
        receiptCode: receiptCode,
        itemsSummary: itemsDescription.isNotEmpty ? itemsDescription : 'Direct Store Terminal Charge',
        isExitVerified: true,
        verifiedAt: DateTime.now(),
      );

      final id = await _dbHelper.insertTransaction(txn);
      final created = txn.copyWith(transactionId: id);

      _merchantTransactions.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = 'Payment failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Merchant Bank Settlement Transfer
  Future<TransactionModel?> settleToBank({
    required int merchantId,
    required double amount,
    required String bankName,
    required String bankAccount,
  }) async {
    if (amount <= 0) {
      _errorMessage = 'Invalid settlement amount';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final txnRef = 'TXN-BNK-${_uuid.v4().substring(0, 8).toUpperCase()}';
      final receiptCode = 'RCP-BNK-${DateTime.now().millisecondsSinceEpoch}';

      final txn = TransactionModel(
        transactionRef: txnRef,
        userId: 1, // Reference merchant admin
        merchantId: merchantId,
        amount: amount,
        transactionType: 'Bank Settlement',
        status: 'Successful',
        dateTime: DateTime.now(),
        receiptCode: receiptCode,
        itemsSummary: 'Instant Settlement to $bankName ($bankAccount)',
        isExitVerified: true,
      );

      final id = await _dbHelper.insertTransaction(txn);
      final created = txn.copyWith(transactionId: id);

      _merchantTransactions.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = 'Settlement failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
