class MerchantModel {
  final int? merchantId;
  final String businessName;
  final String email;
  final String phoneNumber;
  final String password;
  final String bankAccountNumber;
  final String bankName;
  final DateTime dateRegistered;

  MerchantModel({
    this.merchantId,
    required this.businessName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.bankAccountNumber,
    required this.bankName,
    required this.dateRegistered,
  });

  Map<String, dynamic> toMap() {
    return {
      'MerchantID': merchantId,
      'BusinessName': businessName,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'Password': password,
      'BankAccountNumber': bankAccountNumber,
      'BankName': bankName,
      'DateRegistered': dateRegistered.toIso8601String(),
    };
  }

  factory MerchantModel.fromMap(Map<String, dynamic> map) {
    return MerchantModel(
      merchantId: map['MerchantID'] as int?,
      businessName: map['BusinessName'] ?? '',
      email: map['Email'] ?? '',
      phoneNumber: map['PhoneNumber'] ?? '',
      password: map['Password'] ?? '',
      bankAccountNumber: map['BankAccountNumber'] ?? '',
      bankName: map['BankName'] ?? '',
      dateRegistered: map['DateRegistered'] != null
          ? DateTime.parse(map['DateRegistered'])
          : DateTime.now(),
    );
  }

  MerchantModel copyWith({
    int? merchantId,
    String? businessName,
    String? email,
    String? phoneNumber,
    String? password,
    String? bankAccountNumber,
    String? bankName,
    DateTime? dateRegistered,
  }) {
    return MerchantModel(
      merchantId: merchantId ?? this.merchantId,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      dateRegistered: dateRegistered ?? this.dateRegistered,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantModel &&
          runtimeType == other.runtimeType &&
          merchantId == other.merchantId;

  @override
  int get hashCode => merchantId.hashCode;
}
