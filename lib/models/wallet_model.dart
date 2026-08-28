class WalletModel {
  final int? walletId;
  final int userId;
  final double balance;
  final DateTime lastUpdated;

  WalletModel({
    this.walletId,
    required this.userId,
    required this.balance,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'WalletID': walletId,
      'UserID': userId,
      'Balance': balance,
      'LastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      walletId: map['WalletID'] as int?,
      userId: map['UserID'] as int? ?? 1,
      balance: (map['Balance'] is int)
          ? (map['Balance'] as int).toDouble()
          : (map['Balance'] as double? ?? 0.0),
      lastUpdated: map['LastUpdated'] != null
          ? DateTime.parse(map['LastUpdated'])
          : DateTime.now(),
    );
  }

  WalletModel copyWith({
    int? walletId,
    int? userId,
    double? balance,
    DateTime? lastUpdated,
  }) {
    return WalletModel(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class SavedCardModel {
  final String cardId;
  final int userId;
  final String cardNumberMasked;
  final String cardHolderName;
  final String expiryDate;
  final String cardType; // 'Mastercard', 'Visa', 'Verve'
  final String bankName;

  SavedCardModel({
    required this.cardId,
    required this.userId,
    required this.cardNumberMasked,
    required this.cardHolderName,
    required this.expiryDate,
    required this.cardType,
    required this.bankName,
  });

  Map<String, dynamic> toMap() {
    return {
      'CardID': cardId,
      'UserID': userId,
      'CardNumberMasked': cardNumberMasked,
      'CardHolderName': cardHolderName,
      'ExpiryDate': expiryDate,
      'CardType': cardType,
      'BankName': bankName,
    };
  }

  factory SavedCardModel.fromMap(Map<String, dynamic> map) {
    return SavedCardModel(
      cardId: map['CardID'] ?? '',
      userId: map['UserID'] as int? ?? 1,
      cardNumberMasked: map['CardNumberMasked'] ?? '•••• •••• •••• 1234',
      cardHolderName: map['CardHolderName'] ?? 'Valued Customer',
      expiryDate: map['ExpiryDate'] ?? '12/28',
      cardType: map['CardType'] ?? 'Mastercard',
      bankName: map['BankName'] ?? 'Access Bank',
    );
  }
}
