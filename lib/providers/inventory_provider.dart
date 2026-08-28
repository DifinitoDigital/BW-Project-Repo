import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/db_helper.dart';
import '../models/product_model.dart';

class InventoryProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  final Uuid _uuid = const Uuid();

  List<ProductModel> _products = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products {
    return _products.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.qrCodeValue.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  List<ProductModel> get allProductsRaw => _products;
  List<ProductModel> get lowStockProducts => _products.where((p) => p.stockQuantity < 10).toList();
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<String> get categories {
    final set = {'All'};
    for (var p in _products) {
      if (p.category.isNotEmpty) {
        set.add(p.category);
      }
    }
    return set.toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadProducts({int? merchantId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _dbHelper.getAllProducts(merchantId: merchantId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct({
    required int merchantId,
    required String name,
    required String category,
    required double price,
    required int stockQuantity,
    String description = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final qrCode = 'PROD-GWAG-${_uuid.v4().substring(0, 6).toUpperCase()}';
      final newProduct = ProductModel(
        merchantId: merchantId,
        productName: name,
        category: category,
        price: price,
        stockQuantity: stockQuantity,
        qrCodeValue: qrCode,
        description: description,
      );

      final id = await _dbHelper.insertProduct(newProduct);
      _products.insert(0, newProduct.copyWith(productId: id));

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

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _dbHelper.updateProduct(product);
      final index = _products.indexWhere((p) => p.productId == product.productId);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      await _dbHelper.deleteProduct(productId);
      _products.removeWhere((p) => p.productId == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
