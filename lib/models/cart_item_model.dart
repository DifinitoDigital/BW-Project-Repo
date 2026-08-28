import 'product_model.dart';

class CartItemModel {
  final int? cartId;
  final int userId;
  final int productId;
  int quantity;
  final DateTime dateAdded;
  final ProductModel? product;

  CartItemModel({
    this.cartId,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.dateAdded,
    this.product,
  });

  double get totalPrice {
    final unitPrice = product?.price ?? 0.0;
    return unitPrice * quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'CartID': cartId,
      'UserID': userId,
      'ProductID': productId,
      'Quantity': quantity,
      'DateAdded': dateAdded.toIso8601String(),
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map, {ProductModel? product}) {
    return CartItemModel(
      cartId: map['CartID'] as int?,
      userId: map['UserID'] as int? ?? 1,
      productId: map['ProductID'] as int? ?? 1,
      quantity: map['Quantity'] as int? ?? 1,
      dateAdded: map['DateAdded'] != null
          ? DateTime.parse(map['DateAdded'])
          : DateTime.now(),
      product: product,
    );
  }

  CartItemModel copyWith({
    int? cartId,
    int? userId,
    int? productId,
    int? quantity,
    DateTime? dateAdded,
    ProductModel? product,
  }) {
    return CartItemModel(
      cartId: cartId ?? this.cartId,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      dateAdded: dateAdded ?? this.dateAdded,
      product: product ?? this.product,
    );
  }
}
