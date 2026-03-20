// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fixnum/fixnum.dart';
import '../utils/constants.dart';

class ApiService {
  final String baseUrl = WarthogConstants.nodeUrl;

  // 1. Merr informacionin e bllokut aktual (pinHeight, pinHash)
  // GET /chain/head
  Future<Map<String, dynamic>> getChainHead() async {
    try {
      print('🔍 Marrja e chain head...');
      final response = await http.get(
        Uri.parse('$baseUrl/chain/head'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Përgjigjja: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Chain head u mor: pinHeight=${data['data']['pinHeight']}');
        return {
          'pinHeight': data['data']['pinHeight'],
          'pinHash': data['data']['pinHash'],
        };
      } else {
        throw Exception('Failed to get chain head: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting chain head: $e');
      rethrow;
    }
  }

  // 2. Kodimi i tarifës 16-bit
  // GET /tools/encode16bit/from_string/:string
  Future<int> encodeFee16Bit(String feeWart) async {
    try {
      print('🔍 Kodimi i tarifës: $feeWart WART');
      final response = await http.get(
        Uri.parse('$baseUrl/tools/encode16bit/from_string/$feeWart'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feeE8 = data['data']['roundedE8'];
        print('✅ Tarifa e koduar: $feeE8 E8');
        return feeE8;
      } else {
        throw Exception('Failed to encode fee: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error encoding fee: $e');
      rethrow;
    }
  }

  // 3. Merr balancën e një adrese
  // GET /account/:account/balance
  Future<double> getBalance(String address) async {
    try {
      print('🔍 Kontrollo balancën për adresën: $address');
      
      final response = await http.get(
        Uri.parse('$baseUrl/account/$address/balance'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Përgjigjja nga nodi: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final data = responseData['data'];
          final balanceE8 = data['balanceE8'];
          
          if (balanceE8 != null) {
            final balance = balanceE8 / WarthogConstants.e8Multiplier;
            print('💰 Balanca: $balance WART (E8: $balanceE8)');
            return balance;
          }
        }
        return 0.0;
      } else {
        print('❌ Gabim: ${response.statusCode} - ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('❌ Gabim gjatë marrjes së balancës: $e');
      return 0.0;
    }
  }

  // 4. Dërgo transaksion - ME TRAJTIM TË SAKTË TË TXHASH
  // POST /transaction/add
  Future<Map<String, dynamic>> submitTransaction(Map<String, dynamic> txData) async {
    try {
      print('📤 Dërgimi i transaksionit...');
      final response = await http.post(
        Uri.parse('$baseUrl/transaction/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(txData),
      ).timeout(const Duration(seconds: 10));

      print('📥 Përgjigjja: ${response.statusCode}');
      print('📦 Përmbajtja: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Kontrollo nëse ka kod gabimi (code jo 0)
      if (responseData.containsKey('code') && responseData['code'] != 0) {
        String errorMessage = responseData['error'] ?? 'Unknown error';
        print('❌ Gabim nga blockchain: $errorMessage (code: ${responseData['code']})');
        return {
          'success': false,
          'error': errorMessage,
          'code': responseData['code'],
          'data': responseData,
        };
      }

      // Nëse kodi është 0, sukses
      print('✅ Transaksioni u dërgua me sukses!');
      
      // Warthog përdor txHash në data.txHash
      final txHash = responseData['data']?['txHash'];
      final txId = txHash ?? responseData['txId'];
      
      print('📌 Transaksioni ID: $txId');
      
      return {
        'success': true,
        'txId': txId,
        'data': responseData,
      };
      
    } catch (e) {
      print('❌ Gabim gjatë dërgimit: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 5. Merr tarifën minimale të pranuar nga blockchain
  // GET /transaction/minfee
  Future<double> getMinimumFee() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transaction/minfee'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Formati: { "code": 0, "data": { "16bit": 16923, "E8": 100032, "amount": "0.00100032" } }
        final feeE8 = data['data']['E8'] ?? 100032;
        final feeWart = feeE8 / WarthogConstants.e8Multiplier;
        print('💰 Tarifa minimale: $feeWart WART (E8: $feeE8)');
        return feeWart;
      } else {
        return 0.00100032; // Vlera default nga dokumentacioni
      }
    } catch (e) {
      print('Error getting minimum fee: $e');
      return 0.00100032; // Vlera default në rast gabimi
    }
  }

  // 6. Kontrollo statusin e transaksionit
  // GET /transaction/lookup/:txid
  Future<Map<String, dynamic>> getTransactionStatus(String txId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transaction/lookup/$txId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to get transaction status');
      }
    } catch (e) {
      print('Error getting transaction status: $e');
      rethrow;
    }
  }

  // 7. Merr transaksionet e fundit
  // GET /transaction/latest
  Future<List<dynamic>> getLatestTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transaction/latest'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['transactions'] ?? [];
      } else {
        throw Exception('Failed to get latest transactions');
      }
    } catch (e) {
      print('Error getting latest transactions: $e');
      return [];
    }
  }
}