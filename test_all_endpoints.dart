import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // Shto këtë import për funksionin min()

void main() async {
  print('🧪 TESTIMI I TË GJITHA ENDPOINT-EVE TË WARTHOG');
  print('==============================================\n');
  
  // Lista e node-ve për testim
  final nodes = [
    'http://217.182.64.43:3001',
    'https://warthognode.duckdns.org',
    'http://194.163.153.115:3001',
    'http://localhost:3001',
  ];
  
  // Adresa për testim
  final testAddress = '7cb029b49ba51d5dee9934c7e2ae3c963e88b7e2418fe41b';
  
  for (final node in nodes) {
    print('\n📡 ========================================');
    print('📡 TESTIMI I NODIT: $node');
    print('========================================\n');
    
    // Test 1: Chain head
    await testEndpoint(node, '/chain/head', 'Chain Head');
    
    // Test 2: Version
    await testEndpoint(node, '/tools/version', 'Version');
    
    // Test 3: Balance - Endpoint-i i saktë sipas dokumentacionit
    await testEndpoint(node, '/account/$testAddress/balance', 'Balance');
    
    // Test 4: Minimum fee
    await testEndpoint(node, '/transaction/minfee', 'Minimum Fee');
    
    // Test 5: Latest transactions
    await testEndpoint(node, '/transaction/latest', 'Latest Transactions');
    
    // Test 6: Mempool
    await testEndpoint(node, '/transaction/mempool', 'Mempool');
    
    // Test 7: Richlist
    await testEndpoint(node, '/account/richlist', 'Richlist');
    
    // Test 8: Tools version
    await testEndpoint(node, '/tools/version', 'Tools Version');
    
    // Test 9: Encode 16bit test
    await testEndpoint(node, '/tools/encode16bit/from_string/0.01', 'Encode 16bit');
    
    print('\n----------------------------------------\n');
  }
}

Future<void> testEndpoint(String node, String endpoint, String name) async {
  try {
    print('🔍 Testo: $name');
    print('   Endpoint: $node$endpoint');
    
    final response = await http.get(
      Uri.parse('$node$endpoint'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      print('   ✅ PUNON! Status: ${response.statusCode}');
      
      // Shfaq përmbajtjen në varësi të endpoint-it
      if (endpoint.contains('balance')) {
        try {
          final data = json.decode(response.body);
          print('   📊 Balanca E8: ${data['balanceE8']}');
          if (data['balanceE8'] != null) {
            final balance = data['balanceE8'] / 100000000;
            print('   💰 Balanca: $balance WART');
          }
        } catch (e) {
          print('   📦 Përgjigjja: ${response.body}');
        }
      } else if (endpoint.contains('chain/head')) {
        try {
          final data = json.decode(response.body);
          print('   📊 pinHeight: ${data['data']['pinHeight']}');
          print('   📊 pinHash: ${data['data']['pinHash']}');
        } catch (e) {
          print('   📦 Përgjigjja: ${response.body}');
        }
      } else if (endpoint.contains('version')) {
        print('   📦 Përgjigjja: ${response.body}');
      } else {
        // Për endpoint-et e tjera, shfaq 100 karakteret e para
        final preview = response.body.length > 100 
            ? '${response.body.substring(0, 100)}...' 
            : response.body;
        print('   📦 Përgjigjja: $preview');
      }
    } else {
      print('   ❌ Dështoi! Status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        final preview = response.body.length > 100 
            ? '${response.body.substring(0, 100)}...' 
            : response.body;
        print('   📝 Përgjigjja: $preview');
      }
    }
  } catch (e) {
    print('   ❌ Gabim: $e');
  }
}