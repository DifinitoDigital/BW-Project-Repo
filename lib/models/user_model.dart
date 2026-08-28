class UserModel {
  final int? userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final int? walletId;
  final DateTime dateRegistered;

  UserModel({
    this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    this.walletId,
    required this.dateRegistered,
  });

  Map<String, dynamic> toMap() {
    return {
      'UserID': userId,
      'FullName': fullName,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'Password': password,
      'WalletID': walletId,
      'DateRegistered': dateRegistered.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['UserID'] as int?,
      fullName: map['FullName'] ?? '',
      email: map['Email'] ?? '',
      phoneNumber: map['PhoneNumber'] ?? '',
      password: map['Password'] ?? '',
      walletId: map['WalletID'] as int?,
      dateRegistered: map['DateRegistered'] != null
          ? DateTime.parse(map['DateRegistered'])
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    int? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    int? walletId,
    DateTime? dateRegistered,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      walletId: walletId ?? this.walletId,
      dateRegistered: dateRegistered ?? this.dateRegistered,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
