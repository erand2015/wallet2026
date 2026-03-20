// lib/services/storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/wallet.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _walletKey = 'warthog_wallet';

  // 1. RUAJ PORTOFOLIN
  Future<void> saveWallet(Wallet wallet) async {
    final walletJson = json.encode({
      'mnemonic': wallet.mnemonic,
      'privateKey': wallet.privateKey,
      'publicKey': wallet.publicKey,
      'address': wallet.address,
      'derivationPath': wallet.derivationPath,
    });
    
    await _storage.write(key: _walletKey, value: walletJson);
  }

  // 2. NGARKO PORTOFOLIN
  Future<Wallet?> loadWallet() async {
    final walletJson = await _storage.read(key: _walletKey);
    
    if (walletJson == null) {
      return null;
    }
    
    try {
      final Map<String, dynamic> jsonData = json.decode(walletJson); // NDRYSHIMI KËTU!
      return Wallet(
        mnemonic: jsonData['mnemonic'] ?? '',
        privateKey: jsonData['privateKey'] ?? '',
        publicKey: jsonData['publicKey'] ?? '',
        address: jsonData['address'] ?? '',
        derivationPath: jsonData['derivationPath'] ?? '',
      );
    } catch (e) {
      print('Error loading wallet: $e');
      return null;
    }
  }

  // 3. FSHIJ PORTOFOLIN
  Future<void> deleteWallet() async {
    await _storage.delete(key: _walletKey);
  }

  // 4. KONTROLLO NËSE KA PORTOFOL
  Future<bool> hasWallet() async {
    final wallet = await _storage.read(key: _walletKey);
    return wallet != null;
  }
}