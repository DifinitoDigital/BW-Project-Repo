import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/user_model.dart';
import '../models/merchant_model.dart';
import '../models/product_model.dart';
import '../models/wallet_model.dart';
import '../models/wallet_model.dart' as wm;
import '../models/cart_item_model.dart';
import '../models/transaction_model.dart';
import 'seed_data.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'smart_retail_gwagwalada.db';
    } else {
      try {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, 'smart_retail_gwagwalada.db');
      } catch (_) {
        // Fallback for unit tests and headless environments where path_provider channel is not mocked
        path = join(Directory.current.path, 'smart_retail_gwagwalada.db');
      }
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 3.4.1 User Table
    await db.execute('''
      CREATE TABLE Users (
        UserID INTEGER PRIMARY KEY AUTOINCREMENT,
        FullName TEXT NOT NULL,
        Email TEXT NOT NULL UNIQUE,
        PhoneNumber TEXT NOT NULL,
        Password TEXT NOT NULL,
        WalletID INTEGER,
        DateRegistered TEXT NOT NULL
      )
    ''');

    // 3.4.2 Merchant Table
    await db.execute('''
      CREATE TABLE Merchants (
        MerchantID INTEGER PRIMARY KEY AUTOINCREMENT,
        BusinessName TEXT NOT NULL,
        Email TEXT NOT NULL UNIQUE,
        PhoneNumber TEXT NOT NULL,
        Password TEXT NOT NULL,
        BankAccountNumber TEXT NOT NULL,
        BankName TEXT NOT NULL,
        DateRegistered TEXT NOT NULL
      )
    ''');

    // 3.4.3 Product Table
    await db.execute('''
      CREATE TABLE Products (
        ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
        MerchantID INTEGER NOT NULL,
        ProductName TEXT NOT NULL,
        Category TEXT NOT NULL,
        Price REAL NOT NULL,
        StockQuantity INTEGER NOT NULL,
        QRCodeValue TEXT NOT NULL UNIQUE,
        Description TEXT,
        ImageUrl TEXT,
        FOREIGN KEY (MerchantID) REFERENCES Merchants (MerchantID)
      )
    ''');

    // 3.4.4 Wallet Table
    await db.execute('''
      CREATE TABLE Wallets (
        WalletID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID INTEGER NOT NULL UNIQUE,
        Balance REAL NOT NULL,
        LastUpdated TEXT NOT NULL,
        FOREIGN KEY (UserID) REFERENCES Users (UserID)
      )
    ''');

    // 3.4.5 Cart Table
    await db.execute('''
      CREATE TABLE Cart (
        CartID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        Quantity INTEGER NOT NULL,
        DateAdded TEXT NOT NULL,
        FOREIGN KEY (UserID) REFERENCES Users (UserID),
        FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
      )
    ''');

    // 3.4.6 Transaction Table
    await db.execute('''
      CREATE TABLE Transactions (
        TransactionID INTEGER PRIMARY KEY AUTOINCREMENT,
        TransactionRef TEXT NOT NULL UNIQUE,
        UserID INTEGER NOT NULL,
        MerchantID INTEGER NOT NULL,
        Amount REAL NOT NULL,
        TransactionType TEXT NOT NULL,
        Status TEXT NOT NULL,
        DateTime TEXT NOT NULL,
        ReceiptCode TEXT NOT NULL,
        ItemsSummary TEXT,
        IsExitVerified INTEGER DEFAULT 0,
        VerifiedAt TEXT
      )
    ''');

    // 3.4.7 QR Code Table
    await db.execute('''
      CREATE TABLE QRCodes (
        QRCodeID INTEGER PRIMARY KEY AUTOINCREMENT,
        UserID INTEGER,
        ProductID INTEGER,
        QRType TEXT NOT NULL,
        QRData TEXT NOT NULL,
        DateGenerated TEXT NOT NULL
      )
    ''');

    // Saved Cards Table
    await db.execute('''
      CREATE TABLE SavedCards (
        CardID TEXT PRIMARY KEY,
        UserID INTEGER NOT NULL,
        CardNumberMasked TEXT NOT NULL,
        CardHolderName TEXT NOT NULL,
        ExpiryDate TEXT NOT NULL,
        CardType TEXT NOT NULL,
        BankName TEXT NOT NULL
      )
    ''');

    // Seed initial data
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    // Seed Merchants
    for (var m in SeedData.initialMerchants) {
      await db.insert('Merchants', m.toMap());
    }

    // Seed Users
    for (var u in SeedData.initialUsers) {
      await db.insert('Users', u.toMap());
    }

    // Seed Wallets
    for (var w in SeedData.initialWallets) {
      await db.insert('Wallets', w.toMap());
    }

    // Seed Cards
    for (var c in SeedData.initialCards) {
      await db.insert('SavedCards', c.toMap());
    }

    // Seed Products
    for (var p in SeedData.initialProducts) {
      await db.insert('Products', p.toMap());
      // Seed QR Code for each product
      await db.insert('QRCodes', {
        'ProductID': p.productId,
        'QRType': 'Product',
        'QRData': p.qrCodeValue,
        'DateGenerated': DateTime.now().toIso8601String(),
      });
    }

    // Seed some initial demo transactions
    final initialTxns = [
      TransactionModel(
        transactionRef: 'TXN-GWAG-8947291',
        userId: 1,
        merchantId: 1,
        amount: 8300.00,
        transactionType: 'Cart Self-Checkout',
        status: 'Successful',
        dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        receiptCode: 'RCP-GWAG-8947291',
        itemsSummary: 'Peak Milk 400g (1x), Golden Penny Oil 1L (1x)',
        isExitVerified: true,
        verifiedAt: DateTime.now().subtract(const Duration(days: 2, hours: 3, minutes: 50)),
      ),
      TransactionModel(
        transactionRef: 'TXN-GWAG-8947292',
        userId: 1,
        merchantId: 1,
        amount: 50000.00,
        transactionType: 'Wallet Load',
        status: 'Successful',
        dateTime: DateTime.now().subtract(const Duration(days: 5)),
        receiptCode: 'RCP-TOPUP-50000',
        itemsSummary: 'Direct Top-Up via Access Bank Mastercard',
        isExitVerified: false,
      ),
      TransactionModel(
        transactionRef: 'TXN-GWAG-8947293',
        userId: 2,
        merchantId: 1,
        amount: 14500.00,
        transactionType: 'Cart Self-Checkout',
        status: 'Successful',
        dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        receiptCode: 'RCP-GWAG-8947293',
        itemsSummary: 'Royal Stallion Rice 5kg (1x)',
        isExitVerified: true,
        verifiedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 55)),
      ),
    ];

    for (var tx in initialTxns) {
      await db.insert('Transactions', tx.toMap());
    }
  }

  // --- USER CRUD ---
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final res = await db.query('Users', where: 'UserID = ?', whereArgs: [id]);
    if (res.isNotEmpty) return UserModel.fromMap(res.first);
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query('Users', where: 'Email = ?', whereArgs: [email]);
    if (res.isNotEmpty) return UserModel.fromMap(res.first);
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final res = await db.query('Users');
    return res.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    final userId = await db.insert('Users', user.toMap());
    // Create matching wallet
    final walletId = await db.insert('Wallets', {
      'UserID': userId,
      'Balance': 10000.00, // Welcome demo balance
      'LastUpdated': DateTime.now().toIso8601String(),
    });
    await db.update('Users', {'WalletID': walletId}, where: 'UserID = ?', whereArgs: [userId]);
    return userId;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update('Users', user.toMap(), where: 'UserID = ?', whereArgs: [user.userId]);
  }

  // --- MERCHANT CRUD ---
  Future<MerchantModel?> getMerchantById(int id) async {
    final db = await database;
    final res = await db.query('Merchants', where: 'MerchantID = ?', whereArgs: [id]);
    if (res.isNotEmpty) return MerchantModel.fromMap(res.first);
    return null;
  }

  Future<MerchantModel?> getMerchantByEmail(String email) async {
    final db = await database;
    final res = await db.query('Merchants', where: 'Email = ?', whereArgs: [email]);
    if (res.isNotEmpty) return MerchantModel.fromMap(res.first);
    return null;
  }

  Future<List<MerchantModel>> getAllMerchants() async {
    final db = await database;
    final res = await db.query('Merchants');
    return res.map((e) => MerchantModel.fromMap(e)).toList();
  }

  Future<int> insertMerchant(MerchantModel merchant) async {
    final db = await database;
    return await db.insert('Merchants', merchant.toMap());
  }

  Future<int> updateMerchant(MerchantModel merchant) async {
    final db = await database;
    return await db.update('Merchants', merchant.toMap(), where: 'MerchantID = ?', whereArgs: [merchant.merchantId]);
  }

  // --- WALLET OPERATIONS ---
  Future<WalletModel?> getWalletByUserId(int userId) async {
    final db = await database;
    final res = await db.query('Wallets', where: 'UserID = ?', whereArgs: [userId]);
    if (res.isNotEmpty) return WalletModel.fromMap(res.first);
    return null;
  }

  Future<int> updateWalletBalance(int userId, double newBalance) async {
    final db = await database;
    return await db.update(
      'Wallets',
      {
        'Balance': newBalance,
        'LastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'UserID = ?',
      whereArgs: [userId],
    );
  }

  Future<List<wm.SavedCardModel>> getSavedCards(int userId) async {
    final db = await database;
    final res = await db.query('SavedCards', where: 'UserID = ?', whereArgs: [userId]);
    return res.map((e) => wm.SavedCardModel.fromMap(e)).toList();
  }

  Future<void> insertSavedCard(wm.SavedCardModel card) async {
    final db = await database;
    await db.insert('SavedCards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- PRODUCT OPERATIONS ---
  Future<List<ProductModel>> getAllProducts({int? merchantId}) async {
    final db = await database;
    final List<Map<String, dynamic>> res;
    if (merchantId != null) {
      res = await db.query('Products', where: 'MerchantID = ?', whereArgs: [merchantId]);
    } else {
      res = await db.query('Products');
    }
    return res.map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<ProductModel?> getProductByQR(String qrCode) async {
    final db = await database;
    final res = await db.query('Products', where: 'QRCodeValue = ?', whereArgs: [qrCode]);
    if (res.isNotEmpty) return ProductModel.fromMap(res.first);
    return null;
  }

  Future<ProductModel?> getProductById(int productId) async {
    final db = await database;
    final res = await db.query('Products', where: 'ProductID = ?', whereArgs: [productId]);
    if (res.isNotEmpty) return ProductModel.fromMap(res.first);
    return null;
  }

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    final id = await db.insert('Products', product.toMap());
    await db.insert('QRCodes', {
      'ProductID': id,
      'QRType': 'Product',
      'QRData': product.qrCodeValue,
      'DateGenerated': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return await db.update('Products', product.toMap(), where: 'ProductID = ?', whereArgs: [product.productId]);
  }

  Future<int> deleteProduct(int productId) async {
    final db = await database;
    await db.delete('QRCodes', where: 'ProductID = ?', whereArgs: [productId]);
    return await db.delete('Products', where: 'ProductID = ?', whereArgs: [productId]);
  }

  // --- CART OPERATIONS ---
  Future<List<CartItemModel>> getCartItems(int userId) async {
    final db = await database;
    final res = await db.query('Cart', where: 'UserID = ?', whereArgs: [userId]);
    final List<CartItemModel> items = [];
    for (var m in res) {
      final product = await getProductById(m['ProductID'] as int);
      items.add(CartItemModel.fromMap(m, product: product));
    }
    return items;
  }

  Future<void> addToCart(int userId, int productId, {int quantity = 1}) async {
    final db = await database;
    final existing = await db.query(
      'Cart',
      where: 'UserID = ? AND ProductID = ?',
      whereArgs: [userId, productId],
    );

    if (existing.isNotEmpty) {
      final currentQty = existing.first['Quantity'] as int;
      await db.update(
        'Cart',
        {'Quantity': currentQty + quantity},
        where: 'CartID = ?',
        whereArgs: [existing.first['CartID']],
      );
    } else {
      await db.insert('Cart', {
        'UserID': userId,
        'ProductID': productId,
        'Quantity': quantity,
        'DateAdded': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> updateCartItemQuantity(int cartId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete('Cart', where: 'CartID = ?', whereArgs: [cartId]);
    } else {
      await db.update('Cart', {'Quantity': quantity}, where: 'CartID = ?', whereArgs: [cartId]);
    }
  }

  Future<void> removeFromCart(int cartId) async {
    final db = await database;
    await db.delete('Cart', where: 'CartID = ?', whereArgs: [cartId]);
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    await db.delete('Cart', where: 'UserID = ?', whereArgs: [userId]);
  }

  // --- TRANSACTIONS ---
  Future<int> insertTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert('Transactions', txn.toMap());
  }

  Future<List<TransactionModel>> getTransactionsForUser(int userId) async {
    final db = await database;
    final res = await db.query(
      'Transactions',
      where: 'UserID = ?',
      whereArgs: [userId],
      orderBy: 'DateTime DESC',
    );
    return res.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsForMerchant(int merchantId) async {
    final db = await database;
    final res = await db.query(
      'Transactions',
      where: 'MerchantID = ?',
      whereArgs: [merchantId],
      orderBy: 'DateTime DESC',
    );
    return res.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel?> getTransactionByRef(String ref) async {
    final db = await database;
    final res = await db.query('Transactions', where: 'TransactionRef = ?', whereArgs: [ref]);
    if (res.isNotEmpty) return TransactionModel.fromMap(res.first);
    return null;
  }

  Future<TransactionModel?> getTransactionByReceiptCode(String code) async {
    final db = await database;
    final res = await db.query('Transactions', where: 'ReceiptCode = ?', whereArgs: [code]);
    if (res.isNotEmpty) return TransactionModel.fromMap(res.first);
    return null;
  }

  Future<int> markTransactionExitVerified(String ref) async {
    final db = await database;
    return await db.update(
      'Transactions',
      {
        'IsExitVerified': 1,
        'VerifiedAt': DateTime.now().toIso8601String(),
      },
      where: 'TransactionRef = ?',
      whereArgs: [ref],
    );
  }
}
