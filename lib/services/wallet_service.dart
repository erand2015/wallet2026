// lib/services/wallet_service.dart
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:convert/convert.dart';
import 'crypto_service.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../models/wallet.dart';
import '../utils/constants.dart';

class WalletService {
  final CryptoService _crypto = CryptoService();
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Wallet? _currentWallet;

  // 1. KRIJIM I RI PORTOFOLI
  Future<Wallet> createNewWallet({int wordCount = 12}) async {
    final walletData = _crypto.createNewWallet(wordCount: wordCount);
    
    final wallet = Wallet(
      mnemonic: walletData['mnemonic'],
      privateKey: walletData['privateKey'],
      publicKey: walletData['publicKey'],
      address: walletData['address'],
      derivationPath: walletData['derivationPath'],
    );

    // Merr balancën reale nga API
    wallet.balance = await _api.getBalance(wallet.address);
    print('💰 Balanca reale për portofolin e ri: ${wallet.balance} WART');
    
    // Ruaj në mënyrë të sigurt
    await _storage.saveWallet(wallet);
    
    _currentWallet = wallet;
    return wallet;
  }

  // 2. IMPORT NGA MNEMONIC
  Future<Wallet> importFromMnemonic(String mnemonic) async {
    if (!_crypto.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }

    final walletData = _crypto.importFromMnemonic(mnemonic);
    
    final wallet = Wallet(
      mnemonic: walletData['mnemonic'],
      privateKey: walletData['privateKey'],
      publicKey: walletData['publicKey'],
      address: walletData['address'],
      derivationPath: walletData['derivationPath'],
    );

    // Merr balancën reale nga API
    wallet.balance = await _api.getBalance(wallet.address);
    print('💰 Balanca reale për portofolin e importuar: ${wallet.balance} WART');
    
    // Ruaj në mënyrë të sigurt
    await _storage.saveWallet(wallet);
    
    _currentWallet = wallet;
    return wallet;
  }

  // 3. NGARKO PORTOFOLIN E RUAJTUR
  Future<Wallet?> loadWallet() async {
    final wallet = await _storage.loadWallet();
    if (wallet != null) {
      // Merr balancën reale nga API
      wallet.balance = await _api.getBalance(wallet.address);
      print('💰 Balanca reale e ngarkuar: ${wallet.balance} WART');
      _currentWallet = wallet;
    } else {
      print('ℹ️ Nuk u gjet asnjë portofol i ruajtur');
      _currentWallet = null;
    }
    return wallet;
  }

  // 4. RIFRESKO BALANCËN
  Future<double> refreshBalance() async {
    if (_currentWallet == null) {
      // Provo të ngarkosh nga storage
      await loadWallet();
      if (_currentWallet == null) {
        throw Exception('No wallet loaded');
      }
    }
    // Merr balancën reale nga API
    _currentWallet!.balance = await _api.getBalance(_currentWallet!.address);
    print('🔄 Balanca e rifreskuar: ${_currentWallet!.balance} WART');
    return _currentWallet!.balance;
  }

  // 5. DËRGO TRANSAKSION - ME TRAJTIM TË SAKTË TË GABIMEVE
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    required double fee,
  }) async {
    // Sigurohu që kemi një portofol të ngarkuar
    if (_currentWallet == null) {
      await loadWallet();
      if (_currentWallet == null) {
        throw Exception('No wallet loaded. Please import or create a wallet first.');
      }
    }

    print('📤 Dërgimi i transaksionit nga adresa: ${_currentWallet!.address}');
    
    try {
      // Konverto sasinë në E8
      final amountE8 = Int64((amount * WarthogConstants.e8Multiplier).round());
      
      // Merr pinInfo nga nyja
      final pinInfo = await _api.getChainHead();
      print('📌 pinInfo: $pinInfo');
      
      // Kodimi i tarifës 16-bit
      final feeE8 = await _api.encodeFee16Bit(fee.toString());
      print('📌 feeE8: $feeE8');
      
      // Krijo të dhënat e transaksionit (99 bytes)
      final txData = _crypto.createTransactionData(
        amountE8: amountE8,
        feeE8: Int64(feeE8),
        pinHeight: pinInfo['pinHeight'],
        nonceId: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        pinHash: pinInfo['pinHash'],
        toAddress: toAddress,
      );
      print('📌 txData: ${hex.encode(txData).substring(0, 50)}...');
      
      // Nënshkruaj transaksionin
      final privateKeyBytes = hex.decode(_currentWallet!.privateKey);
      final signature = _crypto.signTransaction(
        Uint8List.fromList(privateKeyBytes),
        txData,
      );
      print('📌 signature: ${hex.encode(signature).substring(0, 50)}...');
      
      // Përgatit të dhënat për dërgim
      final submitData = {
        'pinHeight': pinInfo['pinHeight'],
        'nonceId': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'toAddr': toAddress,
        'amountE8': amountE8.toInt(),
        'feeE8': feeE8,
        'signature65': hex.encode(signature),
      };
      
      // Dërgo transaksionin
      final result = await _api.submitTransaction(submitData);
      
      print('📥 Rezultati i API: $result');
      
      if (result['success'] == true) {
        final txId = result['txId'];
        if (txId == null) {
          print('⚠️ Transaksioni u dërgua por txId është null');
          return 'unknown-tx-id';
        }
        print('✅ Transaksioni u dërgua me sukses! TXID: $txId');
        return txId;
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
      
    } catch (e) {
      print('❌ Gabim gjatë dërgimit të transaksionit: $e');
      rethrow;
    }
  }

  // 6. SHKYÇU (fshi portofolin)
  Future<void> logout() async {
    await _storage.deleteWallet();
    _currentWallet = null;
    print('🚪 U shkyç nga portofoli');
  }

  // 7. MERR PORTOFOLIN AKTUAL
  Wallet? get currentWallet => _currentWallet;
}