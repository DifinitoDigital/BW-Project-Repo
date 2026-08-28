import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/db_helper.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import 'wallet_provider.dart';

class CartProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  final Uuid _uuid = const Uuid();

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItemCount {
    return _items.fold(0, (count, item) => count + item.quantity);
  }

  Future<void> loadCart(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbHelper.getCartItems(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Scan QR code and add item to cart
  Future<ProductModel?> scanAndAddToCart({
    required int userId,
    required String qrCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _dbHelper.getProductByQR(qrCode.trim());
      if (product == null) {
        _errorMessage = 'No product matches QR Code: $qrCode';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Add to database
      await _dbHelper.addToCart(userId, product.productId!);

      // Reload cart
      _items = await _dbHelper.getCartItems(userId);
      _isLoading = false;
      notifyListeners();
      return product;
    } catch (e) {
      _errorMessage = 'Scan failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Direct add product
  Future<void> addProductToCart(int userId, ProductModel product, {int quantity = 1}) async {
    if (product.productId == null) return;
    await _dbHelper.addToCart(userId, product.productId!, quantity: quantity);
    _items = await _dbHelper.getCartItems(userId);
    notifyListeners();
  }

  // Update item quantity
  Future<void> updateQuantity(int cartId, int newQuantity, int userId) async {
    await _dbHelper.updateCartItemQuantity(cartId, newQuantity);
    _items = await _dbHelper.getCartItems(userId);
    notifyListeners();
  }

  // Remove item
  Future<void> removeItem(int cartId, int userId) async {
    await _dbHelper.removeFromCart(cartId);
    _items = await _dbHelper.getCartItems(userId);
    notifyListeners();
  }

  // Clear cart
  Future<void> clearCart(int userId) async {
    await _dbHelper.clearCart(userId);
    _items = [];
    notifyListeners();
  }

  // Self-Checkout with offline wallet deduction & Exit Receipt generation
  Future<TransactionModel?> checkout({
    required int userId,
    required int merchantId,
    required WalletProvider walletProvider,
  }) async {
    if (_items.isEmpty) {
      _errorMessage = 'Your cart is empty';
      notifyListeners();
      return null;
    }

    final total = totalAmount;
    if (walletProvider.balance < total) {
      _errorMessage = 'Insufficient wallet balance. Please fund your wallet first.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Deduct from wallet
      final deducted = await walletProvider.deductAmount(userId, total);
      if (!deducted) {
        _errorMessage = 'Failed to deduct wallet funds';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // 2. Build items summary
      final itemsSummary = _items.map((i) {
        return '${i.product?.productName ?? 'Item'} (${i.quantity}x @ ₦${i.product?.price ?? 0})';
      }).join(', ');

      // 3. Update stock levels for each product
      for (var item in _items) {
        if (item.product != null && item.product!.productId != null) {
          final newStock = (item.product!.stockQuantity - item.quantity).clamp(0, 99999);
          final updatedProduct = item.product!.copyWith(stockQuantity: newStock);
          await _dbHelper.updateProduct(updatedProduct);
        }
      }

      // 4. Generate transaction and receipt
      final txnRef = 'TXN-GWAG-${_uuid.v4().substring(0, 8).toUpperCase()}';
      final receiptCode = 'RCP-EXIT-${_uuid.v4().substring(0, 8).toUpperCase()}';

      final txn = TransactionModel(
        transactionRef: txnRef,
        userId: userId,
        merchantId: merchantId,
        amount: total,
        transactionType: 'Cart Self-Checkout',
        status: 'Successful',
        dateTime: DateTime.now(),
        receiptCode: receiptCode,
        itemsSummary: itemsSummary,
        isExitVerified: false,
      );

      final txnId = await _dbHelper.insertTransaction(txn);

      // 5. Clear cart
      await _dbHelper.clearCart(userId);
      _items = [];

      _isLoading = false;
      notifyListeners();

      return txn.copyWith(transactionId: txnId);
    } catch (e) {
      _errorMessage = 'Checkout failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
