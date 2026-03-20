// lib/providers/wallet_provider.dart
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  
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
      _wallet = await _walletService.loadWallet();
      if (_wallet != null) {
        _balance = _wallet!.balance;
        _address = _wallet!.address;
        print('✅ Portofoli u ngarkua me balancë: $_balance WART');
        print('   Address: $_address');
        print('   Private Key: ${_wallet!.privateKey.substring(0, 16)}...');
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
      print('✅ Portofoli i ri u krijua me balancë: $_balance WART');
      print('   Address: $_address');
      print('   Private Key: ${_wallet!.privateKey.substring(0, 16)}...');
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
      print('✅ Portofoli i importuar me sukses!');
      print('   Address: $_address');
      print('   Private Key: ${_wallet!.privateKey.substring(0, 16)}...');
      print('   Balance: $_balance WART');
    } catch (e) {
      print('❌ Error importing wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalance() async {
    if (_wallet == null) {
      // Provo të ngarkosh nga storage
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
    await _walletService.logout();
    _wallet = null;
    _balance = 0.0;
    _address = '';
    print('🚪 U shkyç nga portofoli');
    notifyListeners();
  }
}