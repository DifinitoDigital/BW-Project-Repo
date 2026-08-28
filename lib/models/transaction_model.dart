class TransactionModel {
  final int? transactionId;
  final String transactionRef;
  final int userId;
  final int merchantId;
  final double amount;
  final String transactionType; // 'Cart Self-Checkout', 'Wallet Load', 'Direct Merchant Pay', 'Bank Settlement', 'Prepaid Recharge'
  final String status; // 'Successful', 'Pending', 'Failed'
  final DateTime dateTime;
  final String receiptCode;
  final String itemsSummary;
  final bool isExitVerified;
  final DateTime? verifiedAt;

  TransactionModel({
    this.transactionId,
    required this.transactionRef,
    required this.userId,
    required this.merchantId,
    required this.amount,
    required this.transactionType,
    required this.status,
    required this.dateTime,
    required this.receiptCode,
    this.itemsSummary = '',
    this.isExitVerified = false,
    this.verifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'TransactionID': transactionId,
      'TransactionRef': transactionRef,
      'UserID': userId,
      'MerchantID': merchantId,
      'Amount': amount,
      'TransactionType': transactionType,
      'Status': status,
      'DateTime': dateTime.toIso8601String(),
      'ReceiptCode': receiptCode,
      'ItemsSummary': itemsSummary,
      'IsExitVerified': isExitVerified ? 1 : 0,
      'VerifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['TransactionID'] as int?,
      transactionRef: map['TransactionRef'] ?? '',
      userId: map['UserID'] as int? ?? 1,
      merchantId: map['MerchantID'] as int? ?? 1,
      amount: (map['Amount'] is int)
          ? (map['Amount'] as int).toDouble()
          : (map['Amount'] as double? ?? 0.0),
      transactionType: map['TransactionType'] ?? 'Cart Self-Checkout',
      status: map['Status'] ?? 'Successful',
      dateTime: map['DateTime'] != null
          ? DateTime.parse(map['DateTime'])
          : DateTime.now(),
      receiptCode: map['ReceiptCode'] ?? '',
      itemsSummary: map['ItemsSummary'] ?? '',
      isExitVerified: (map['IsExitVerified'] == 1 || map['IsExitVerified'] == true),
      verifiedAt: map['VerifiedAt'] != null
          ? DateTime.parse(map['VerifiedAt'])
          : null,
    );
  }

  TransactionModel copyWith({
    int? transactionId,
    String? transactionRef,
    int? userId,
    int? merchantId,
    double? amount,
    String? transactionType,
    String? status,
    DateTime? dateTime,
    String? receiptCode,
    String? itemsSummary,
    bool? isExitVerified,
    DateTime? verifiedAt,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      transactionRef: transactionRef ?? this.transactionRef,
      userId: userId ?? this.userId,
      merchantId: merchantId ?? this.merchantId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      status: status ?? this.status,
      dateTime: dateTime ?? this.dateTime,
      receiptCode: receiptCode ?? this.receiptCode,
      itemsSummary: itemsSummary ?? this.itemsSummary,
      isExitVerified: isExitVerified ?? this.isExitVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
