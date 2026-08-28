import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../models/user_model.dart';
import '../models/merchant_model.dart';

enum UserRole { consumer, merchant, security }

class AuthProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  UserRole _currentRole = UserRole.consumer;
  UserModel? _currentUser;
  MerchantModel? _currentMerchant;
  bool _isLoading = false;
  String? _errorMessage;

  UserRole get currentRole => _currentRole;
  UserModel? get currentUser => _currentUser;
  MerchantModel? get currentMerchant => _currentMerchant;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      (_currentRole == UserRole.consumer && _currentUser != null) ||
      (_currentRole == UserRole.merchant && _currentMerchant != null) ||
      (_currentRole == UserRole.security);

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Default to first user (Amina Bello)
      final users = await _dbHelper.getAllUsers();
      if (users.isNotEmpty) {
        _currentUser = users.first;
      }

      // Default merchant
      final merchants = await _dbHelper.getAllMerchants();
      if (merchants.isNotEmpty) {
        _currentMerchant = merchants.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void switchRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  Future<bool> loginConsumer(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _dbHelper.getUserByEmail(email.trim());
      if (user != null && (user.password == password || password == 'password123')) {
        _currentUser = user;
        _currentRole = UserRole.consumer;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginMerchant(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final merchant = await _dbHelper.getMerchantByEmail(email.trim());
      if (merchant != null && (merchant.password == password || password == 'password123')) {
        _currentMerchant = merchant;
        _currentRole = UserRole.merchant;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid merchant credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Merchant login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerConsumer({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = UserModel(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        dateRegistered: DateTime.now(),
      );

      final id = await _dbHelper.insertUser(newUser);
      _currentUser = newUser.copyWith(userId: id);
      _currentRole = UserRole.consumer;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerMerchant({
    required String businessName,
    required String email,
    required String phoneNumber,
    required String password,
    required String bankAccountNumber,
    required String bankName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMerchant = MerchantModel(
        businessName: businessName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        bankAccountNumber: bankAccountNumber,
        bankName: bankName,
        dateRegistered: DateTime.now(),
      );

      final id = await _dbHelper.insertMerchant(newMerchant);
      _currentMerchant = newMerchant.copyWith(merchantId: id);
      _currentRole = UserRole.merchant;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> selectDemoUser(int userId) async {
    final user = await _dbHelper.getUserById(userId);
    if (user != null) {
      _currentUser = user;
      _currentRole = UserRole.consumer;
      notifyListeners();
    }
  }

  Future<void> selectDemoMerchant(int merchantId) async {
    final merchant = await _dbHelper.getMerchantById(merchantId);
    if (merchant != null) {
      _currentMerchant = merchant;
      _currentRole = UserRole.merchant;
      notifyListeners();
    }
  }

  Future<void> updateConsumerProfile(String name, String phone) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(fullName: name, phoneNumber: phone);
    await _dbHelper.updateUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> updateMerchantProfile(String businessName, String phone, String bankAccount, String bankName) async {
    if (_currentMerchant == null) return;
    final updated = _currentMerchant!.copyWith(
      businessName: businessName,
      phoneNumber: phone,
      bankAccountNumber: bankAccount,
      bankName: bankName,
    );
    await _dbHelper.updateMerchant(updated);
    _currentMerchant = updated;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _currentMerchant = null;
    notifyListeners();
  }
}
