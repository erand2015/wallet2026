// lib/providers/wallet_provider.dart
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../services/storage_service.dart';
import '../models/wallet.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  final StorageService _storageService = StorageService();
  
  Wallet? _wallet;
  double _balance = 0.0;
  bool _isLoading = false;
  String _address = '';

  Wallet? get wallet => _wallet;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String get address => _address;

  Future<void> loadWallet() async {
    _isLoading = true;
    notifyListeners();

    try {
      _wallet = await _storageService.loadWallet();
      if (_wallet != null) {
        _balance = await _walletService.refreshBalance();
        _wallet!.balance = _balance;
        _address = _wallet!.address;
        print('✅ Portofoli u ngarkua: $_address');
        print('✅ Balanca: $_balance WART');
      } else {
        print('ℹ️ Nuk ka portofol të ruajtur');
      }
    } catch (e) {
      print('❌ Error loading wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNewWallet({int wordCount = 12}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _wallet = await _walletService.createNewWallet(wordCount: wordCount);
      _balance = _wallet!.balance;
      _address = _wallet!.address;
      
      // Ruaj në storage
      await _storageService.saveWallet(_wallet!);
      
      print('✅ Portofoli i ri u krijua: $_address');
      print('✅ Balanca: $_balance WART');
    } catch (e) {
      print('❌ Error creating wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importWallet(String mnemonic) async {
    _isLoading = true;
    notifyListeners();

    try {
      _wallet = await _walletService.importFromMnemonic(mnemonic);
      _balance = _wallet!.balance;
      _address = _wallet!.address;
      
      // Ruaj në storage
      await _storageService.saveWallet(_wallet!);
      
      print('✅ Portofoli i importuar: $_address');
      print('✅ Ruajtur në storage');
      print('✅ Balanca: $_balance WART');
    } catch (e) {
      print('❌ Error importing wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    if (_wallet == null) {
      await loadWallet();
      if (_wallet == null) return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _balance = await _walletService.refreshBalance();
      _wallet!.balance = _balance;
      print('🔄 Balanca e rifreskuar: $_balance WART');
    } catch (e) {
      print('❌ Error refreshing balance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storageService.deleteWallet();
    _wallet = null;
    _balance = 0.0;
    _address = '';
    print('🚪 U shkyç nga portofoli');
    notifyListeners();
  }
}