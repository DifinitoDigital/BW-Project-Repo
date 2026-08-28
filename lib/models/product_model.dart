class ProductModel {
  final int? productId;
  final int merchantId;
  final String productName;
  final String category;
  final double price;
  final int stockQuantity;
  final String qrCodeValue;
  final String description;
  final String imageUrl;

  ProductModel({
    this.productId,
    required this.merchantId,
    required this.productName,
    this.category = 'General',
    required this.price,
    this.stockQuantity = 50,
    required this.qrCodeValue,
    this.description = '',
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'ProductID': productId,
      'MerchantID': merchantId,
      'ProductName': productName,
      'Category': category,
      'Price': price,
      'StockQuantity': stockQuantity,
      'QRCodeValue': qrCodeValue,
      'Description': description,
      'ImageUrl': imageUrl,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId: map['ProductID'] as int?,
      merchantId: map['MerchantID'] as int? ?? 1,
      productName: map['ProductName'] ?? '',
      category: map['Category'] ?? 'General',
      price: (map['Price'] is int)
          ? (map['Price'] as int).toDouble()
          : (map['Price'] as double? ?? 0.0),
      stockQuantity: map['StockQuantity'] as int? ?? 50,
      qrCodeValue: map['QRCodeValue'] ?? '',
      description: map['Description'] ?? '',
      imageUrl: map['ImageUrl'] ?? '',
    );
  }

  ProductModel copyWith({
    int? productId,
    int? merchantId,
    String? productName,
    String? category,
    double? price,
    int? stockQuantity,
    String? qrCodeValue,
    String? description,
    String? imageUrl,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      merchantId: merchantId ?? this.merchantId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
