// lib/services/transaction_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../utils/constants.dart';

class TransactionService {
  final String baseUrl = WarthogConstants.nodeUrl;

  // Merr historikun e transaksioneve për një adresë
  Future<List<Transaction>> getTransactionHistory(String address, {int beforeIndex = 0}) async {
    try {
      print('🔍 Marrja e historikut për adresën: $address');
      
      final response = await http.get(
        Uri.parse('$baseUrl/account/$address/history/$beforeIndex'),
      ).timeout(const Duration(seconds: 10));

      print('📡 Përgjigjja: ${response.statusCode}');
      print('📦 Përgjigjja e plotë: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Transaksionet janë te data['perBlock']
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final data = responseData['data'];
          final List<dynamic> perBlock = data['perBlock'] ?? [];
          
          print('📦 perBlock përmban ${perBlock.length} elemente');
          
          if (perBlock.isEmpty) {
            print('⚠️ Nuk ka transaksione në perBlock');
            return [];
          }
          
          // Konverto çdo bllok në transaksione
          List<Transaction> allTxs = [];
          for (var block in perBlock) {
            print('📦 Bloku: $block');
            final txs = block['body']?['transfers'] ?? [];
            for (var tx in txs) {
              allTxs.add(_parseTransaction(tx, block));
            }
          }
          
          print('📦 Gjetur ${allTxs.length} transaksione');
          return allTxs;
        }
        
        return [];
      } else {
        print('❌ Gabim: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Gabim gjatë marrjes së historikut: $e');
      return [];
    }
  }

  // Konverton përgjigjen nga API në objekt Transaction
  Transaction _parseTransaction(Map<String, dynamic> tx, Map<String, dynamic> block) {
    return Transaction(
      txId: tx['txId'] ?? tx['txHash'] ?? 'unknown',
      from: tx['from'] ?? '',
      to: tx['to'] ?? '',
      amount: _parseAmount(tx['amount']),
      fee: _parseAmount(tx['fee']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(block['timestamp'] ?? 0),
      status: TransactionStatus.confirmed,
    );
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount / 100000000;
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }
}