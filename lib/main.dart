import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/db_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/security_provider.dart';
import 'utils/app_theme.dart';
import 'views/splash/splash_screen.dart';
import 'views/auth/auth_screen.dart';
import 'views/consumer/consumer_main_screen.dart';
import 'views/merchant/merchant_main_screen.dart';
import 'views/security/exit_security_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI on desktop platforms (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Preload and seed local SQLite database
  await DBHelper().database;

  runApp(const SmartRetailPayApp());
}

class SmartRetailPayApp extends StatelessWidget {
  const SmartRetailPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initAuth()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()..loadProducts()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Smart Retail Pay (Gwagwalada FCT)',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/splash': (context) => const SplashScreen(),
              '/auth': (context) => const AuthScreen(),
              '/consumer': (context) => const ConsumerMainScreen(),
              '/merchant': (context) => const MerchantMainScreen(),
              '/security': (context) => const ExitSecurityScreen(),
            },
          );
        },
      ),
    );
  }
}
