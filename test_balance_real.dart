import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🧪 TESTIMI I BALANCËS PËR ADRESA TË NDRYSHME');
  print('==============================================\n');
  
  final node = 'http://217.182.64.43:3001';
  
  // Adresa për testim
  final addresses = [
    '7cb029b49ba51d5dee9934c7e2ae3c963e88b7e2418fe41b', // Adresa jote 12 fjalë
    '8c3c95b1497bf0c83815ce1ba71d808a156546192845db97', // Adresa jote 24 fjalë
    '93a1f9ca54a6ec9cc451c776fd97c94be9fbfc7e4a2fbdb5', // Nga richlist
    '0000000000000000000000000000000000000000de47c9b2', // Adresa zero
  ];
  
  for (final address in addresses) {
    try {
      final response = await http.get(
        Uri.parse('$node/account/$address/balance'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final balanceE8 = data['balanceE8'];
        
        if (balanceE8 == null) {
          print('📌 Adresa: $address');
          print('   ❌ balanceE8 = null (pa monedha)');
        } else {
          final balance = balanceE8 / 100000000;
          print('📌 Adresa: $address');
          print('   ✅ BALANCA: $balance WART (E8: $balanceE8)');
        }
      } else {
        print('📌 Adresa: $address');
        print('   ❌ Gabim: ${response.statusCode}');
      }
    } catch (e) {
      print('📌 Adresa: $address');
      print('   ❌ Gabim: $e');
    }
    print('');
  }
}