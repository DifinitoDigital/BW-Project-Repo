import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/db_helper.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class WalletProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  final Uuid _uuid = const Uuid();

  WalletModel? _currentWallet;
  List<SavedCardModel> _savedCards = [];
  bool _isLoading = false;
  String? _errorMessage;

  WalletModel? get currentWallet => _currentWallet;
  double get balance => _currentWallet?.balance ?? 0.0;
  List<SavedCardModel> get savedCards => _savedCards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadWallet(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      var wallet = await _dbHelper.getWalletByUserId(userId);
      if (wallet == null) {
        // Create initial wallet if missing
        await _dbHelper.database;
        wallet = await _dbHelper.getWalletByUserId(userId);
      }
      _currentWallet = wallet;
      _savedCards = await _dbHelper.getSavedCards(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Preload / Fund Wallet (Offline instant card charge simulator)
  Future<bool> fundWallet({
    required int userId,
    required double amount,
    required String fundingMethod, // e.g. 'Access Bank Mastercard (4821)', 'Direct Bank Transfer'
  }) async {
    if (amount <= 0) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final newBalance = balance + amount;
      await _dbHelper.updateWalletBalance(userId, newBalance);

      // Create transaction log
      final txnRef = 'TXN-TOP-${_uuid.v4().substring(0, 8).toUpperCase()}';
      final receiptCode = 'RCP-TOP-${DateTime.now().millisecondsSinceEpoch}';

      final txn = TransactionModel(
        transactionRef: txnRef,
        userId: userId,
        merchantId: 1, // Default system merchant
        amount: amount,
        transactionType: 'Wallet Load',
        status: 'Successful',
        dateTime: DateTime.now(),
        receiptCode: receiptCode,
        itemsSummary: 'Preloaded ₦$amount via $fundingMethod',
        isExitVerified: false,
      );

      await _dbHelper.insertTransaction(txn);

      // Update in-memory wallet
      _currentWallet = _currentWallet?.copyWith(
        balance: newBalance,
        lastUpdated: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Deduct from wallet
  Future<bool> deductAmount(int userId, double amount) async {
    if (balance < amount) return false;

    final newBalance = balance - amount;
    await _dbHelper.updateWalletBalance(userId, newBalance);

    _currentWallet = _currentWallet?.copyWith(
      balance: newBalance,
      lastUpdated: DateTime.now(),
    );

    notifyListeners();
    return true;
  }

  // Save new card
  Future<void> addCard(int userId, String cardNumber, String cardHolder, String expiry, String type, String bank) async {
    final masked = '•••• •••• •••• ${cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : '1234'}';
    final card = SavedCardModel(
      cardId: 'CARD-${_uuid.v4().substring(0, 6)}',
      userId: userId,
      cardNumberMasked: masked,
      cardHolderName: cardHolder.toUpperCase(),
      expiryDate: expiry,
      cardType: type,
      bankName: bank,
    );

    await _dbHelper.insertSavedCard(card);
    _savedCards.add(card);
    notifyListeners();
  }

  // Recharge prepaid number (Section 3.2 feature)
  Future<bool> rechargePrepaid({
    required int userId,
    required String phoneNumber,
    required String network, // MTN, Airtel, Glo, 9mobile
    required double amount,
  }) async {
    if (balance < amount) return false;

    final success = await deductAmount(userId, amount);
    if (!success) return false;

    final txnRef = 'TXN-AIR-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final receiptCode = 'RCP-AIR-${DateTime.now().millisecondsSinceEpoch}';

    final txn = TransactionModel(
      transactionRef: txnRef,
      userId: userId,
      merchantId: 1,
      amount: amount,
      transactionType: 'Prepaid Recharge',
      status: 'Successful',
      dateTime: DateTime.now(),
      receiptCode: receiptCode,
      itemsSummary: '$network ₦$amount Airtime Top-Up to $phoneNumber',
      isExitVerified: false,
    );

    await _dbHelper.insertTransaction(txn);
    return true;
  }
}
