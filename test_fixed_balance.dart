import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🧪 TESTI I RREGULLUAR PËR BALANCË');
  print('=================================\n');
  
  final node = 'http://217.182.64.43:3001';
  final yourAddress = '4b46557f77181950326fa319c409e64c410fb0c4d5904b1b';
  
  print('📌 Adresa: $yourAddress');
  
  try {
    final response = await http.get(
      Uri.parse('$node/account/$yourAddress/balance'),
    ).timeout(const Duration(seconds: 10));
    
    print('📡 Përgjigjja nga nodi: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      print('📦 Përgjigjja e plotë: $responseData');
      
      // Tani trajtojmë strukturën e saktë
      if (responseData.containsKey('data')) {
        final data = responseData['data'];
        final balanceE8 = data['balanceE8'];
        final accountId = data['accountId'];
        final address = data['address'];
        
        print('\n✅ TË DHËNAT E NYJES:');
        print('   Account ID: $accountId');
        print('   Address: $address');
        print('   Balance E8: $balanceE8');
        
        if (balanceE8 != null) {
          final balance = balanceE8 / 100000000;
          print('   💰 BALANCA REALE: $balance WART');
        }
      }
    }
  } catch (e) {
    print('❌ Gabim: $e');
  }
}