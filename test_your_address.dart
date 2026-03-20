import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🧪 TESTIMI I BALANCËS PËR ADRESËN TËNDE');
  print('========================================\n');
  
  final node = 'http://217.182.64.43:3001';
  final yourAddress = '4b46557f77181950326fa319c409e64c410fb0c4d5904b1b';
  
  print('📌 Adresa: $yourAddress');
  
  try {
    final response = await http.get(
      Uri.parse('$node/account/$yourAddress/balance'),
    ).timeout(const Duration(seconds: 10));
    
    print('📡 Përgjigjja nga nodi: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('📦 Të dhënat e marra: $data');
      
      final balanceE8 = data['balanceE8'];
      if (balanceE8 == null) {
        print('❌ balanceE8 = null (pa monedha ose adresë e panjohur)');
      } else {
        final balance = balanceE8 / 100000000;
        print('💰 BALANCA: $balance WART (E8: $balanceE8)');
      }
    } else {
      print('❌ Gabim: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Gabim gjatë kërkesës: $e');
  }
}