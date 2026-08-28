class QRCodeModel {
  final int? qrCodeId;
  final int? userId;
  final int? productId;
  final String qrType; // 'Consumer', 'Product', 'ExitReceipt'
  final String qrData;
  final DateTime dateGenerated;

  QRCodeModel({
    this.qrCodeId,
    this.userId,
    this.productId,
    required this.qrType,
    required this.qrData,
    required this.dateGenerated,
  });

  Map<String, dynamic> toMap() {
    return {
      'QRCodeID': qrCodeId,
      'UserID': userId,
      'ProductID': productId,
      'QRType': qrType,
      'QRData': qrData,
      'DateGenerated': dateGenerated.toIso8601String(),
    };
  }

  factory QRCodeModel.fromMap(Map<String, dynamic> map) {
    return QRCodeModel(
      qrCodeId: map['QRCodeID'] as int?,
      userId: map['UserID'] as int?,
      productId: map['ProductID'] as int?,
      qrType: map['QRType'] ?? 'Product',
      qrData: map['QRData'] ?? '',
      dateGenerated: map['DateGenerated'] != null
          ? DateTime.parse(map['DateGenerated'])
          : DateTime.now(),
    );
  }
}
