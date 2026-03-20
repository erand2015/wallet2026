// lib/models/wallet.dart
class Wallet {
  final String mnemonic;
  final String privateKey;
  final String publicKey;
  final String address;
  final String derivationPath;
  double balance;
  
  Wallet({
    required this.mnemonic,
    required this.privateKey,
    required this.publicKey,
    required this.address,
    required this.derivationPath,
    this.balance = 0.0,
  });
  
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      mnemonic: json['mnemonic'] ?? '',
      privateKey: json['privateKey'] ?? '',
      publicKey: json['publicKey'] ?? '',
      address: json['address'] ?? '',
      derivationPath: json['derivationPath'] ?? '',
      balance: json['balance']?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'mnemonic': mnemonic,
      'privateKey': privateKey,
      'publicKey': publicKey,
      'address': address,
      'derivationPath': derivationPath,
      'balance': balance,
    };
  }
}