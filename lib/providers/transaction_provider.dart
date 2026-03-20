// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'local_transactions';
  
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => _transactions;

  // Ngarko transaksionet nga storage lokal
  Future<void> loadTransactions() async {
    try {
      final String? stored = await _storage.read(key: _storageKey);
      if (stored != null) {
        final List<dynamic> jsonList = json.decode(stored);
        _transactions = jsonList.map((json) => Transaction.fromJson(json)).toList();
        print('📦 Ngarkuan ${_transactions.length} transaksione lokale');
      } else {
        _transactions = [];
      }
    } catch (e) {
      print('❌ Gabim gjatë ngarkimit të transaksioneve: $e');
      _transactions = [];
    }
    notifyListeners();
  }

  // Shto një transaksion të ri
  Future<void> addTransaction(Transaction tx) async {
    _transactions.insert(0, tx); // Shto në fillim (më i fundit)
    await _saveTransactions();
    notifyListeners();
    print('✅ Transaksioni u ruajt lokal: ${tx.txId}');
  }

  // Përditëso statusin e një transaksioni
  Future<void> updateTransactionStatus(String txId, TransactionStatus status) async {
    final index = _transactions.indexWhere((tx) => tx.txId == txId);
    if (index != -1) {
      _transactions[index] = Transaction(
        txId: _transactions[index].txId,
        from: _transactions[index].from,
        to: _transactions[index].to,
        amount: _transactions[index].amount,
        fee: _transactions[index].fee,
        timestamp: _transactions[index].timestamp,
        status: status,
      );
      await _saveTransactions();
      notifyListeners();
    }
  }

  // Ruaj transaksionet në storage
  Future<void> _saveTransactions() async {
    try {
      final jsonList = _transactions.map((tx) => tx.toJson()).toList();
      await _storage.write(key: _storageKey, value: json.encode(jsonList));
    } catch (e) {
      print('❌ Gabim gjatë ruajtjes së transaksioneve: $e');
    }
  }

  // Fshi të gjitha transaksionet (p.sh. kur bëhet logout)
  Future<void> clearTransactions() async {
    _transactions.clear();
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }
}