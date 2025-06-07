class SaldoUserModel {
  final String userId;
  final double saldo;

  SaldoUserModel({
    required this.userId,
    required this.saldo,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'saldo': saldo,
    };
  }

  factory SaldoUserModel.fromMap(Map<String, dynamic> map) {
    return SaldoUserModel(
      userId: map['userId'] as String,
      saldo: map['saldo'] as double,
    );
  }
}