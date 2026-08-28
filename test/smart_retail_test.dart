import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smart_retail_pay/data/db_helper.dart';
import 'package:smart_retail_pay/models/product_model.dart';
import 'package:smart_retail_pay/models/cart_item_model.dart';
import 'package:smart_retail_pay/providers/security_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Gwagwalada Smart Retail Offline Tests', () {
    test('Database seeds initial products, users, merchants, and wallets', () async {
      final dbHelper = DBHelper();
      final products = await dbHelper.getAllProducts();
      expect(products.isNotEmpty, true);
      expect(products.length >= 10, true);

      final users = await dbHelper.getAllUsers();
      expect(users.isNotEmpty, true);
      expect(users.first.fullName, 'Amina Bello');

      final merchants = await dbHelper.getAllMerchants();
      expect(merchants.isNotEmpty, true);
      expect(merchants.first.businessName, 'Gwagwalada Supermarket Ltd');

      final wallet = await dbHelper.getWalletByUserId(1);
      expect(wallet != null, true);
      expect(wallet!.balance > 0, true);
    });

    test('Product QR code lookup works offline', () async {
      final dbHelper = DBHelper();
      final product = await dbHelper.getProductByQR('PROD-GWAG-001');
      expect(product != null, true);
      expect(product!.productName.contains('Peak Full Cream Milk'), true);
      expect(product.price, 3800.00);
    });

    test('Cart calculations and live running total', () {
      final prod1 = ProductModel(
        productId: 1,
        merchantId: 1,
        productName: 'Peak Milk',
        price: 3800.00,
        qrCodeValue: 'PROD-001',
      );
      final prod2 = ProductModel(
        productId: 2,
        merchantId: 1,
        productName: 'Golden Penny Oil',
        price: 4500.00,
        qrCodeValue: 'PROD-002',
      );

      final item1 = CartItemModel(
        cartId: 1,
        userId: 1,
        productId: 1,
        quantity: 2,
        dateAdded: DateTime.now(),
        product: prod1,
      );
      final item2 = CartItemModel(
        cartId: 2,
        userId: 1,
        productId: 2,
        quantity: 1,
        dateAdded: DateTime.now(),
        product: prod2,
      );

      expect(item1.totalPrice, 7600.00);
      expect(item2.totalPrice, 4500.00);
      expect(item1.totalPrice + item2.totalPrice, 12100.00);
    });

    test('Security Provider verifies valid exit receipts and catches duplicates', () async {
      final securityProvider = SecurityProvider();

      // Test already verified receipt from seed data
      await securityProvider.verifyReceipt('RCP-GWAG-8947291');
      expect(securityProvider.status, VerificationStatus.alreadyVerified);

      // Test invalid receipt
      await securityProvider.verifyReceipt('RCP-FAKE-999999');
      expect(securityProvider.status, VerificationStatus.invalid);
    });
  });
}
