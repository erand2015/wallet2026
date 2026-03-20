import 'lib/services/api_service.dart';
import 'lib/utils/constants.dart';

void main() async {
  print('🧪 TESTIMI I API-SË PËR BALANCAT REALE');
  print('=======================================\n');
  
  final api = ApiService();
  
  // Testo me adresën e 12 fjalëve
  print('📌 Testo adresën 12 fjalëve:');
  print('Adresa: ${WarthogConstants.testAddress12}');
  final balance12 = await api.getBalance(WarthogConstants.testAddress12);
  print('💰 Balanca: $balance12 WART\n');
  
  // Testo me adresën e 24 fjalëve
  print('📌 Testo adresën 24 fjalëve:');
  print('Adresa: ${WarthogConstants.testAddress24}');
  final balance24 = await api.getBalance(WarthogConstants.testAddress24);
  print('💰 Balanca: $balance24 WART\n');
  
  // Testo me adresë të rastit
  print('📌 Testo adresë të rastit:');
  final randomAddress = '7cb029b49ba51d5dee9934c7e2ae3c963e88b7e2418fe41b';
  final balanceRandom = await api.getBalance(randomAddress);
  print('💰 Balanca: $balanceRandom WART');
}