import 'package:convert/convert.dart';
import 'lib/services/crypto_service.dart';
import 'lib/utils/constants.dart';

void main() {
  print('🧪 TESTIMI PËRFUNDIMTAR I CRYPTO SERVICE');
  print('=========================================\n');
  
  final crypto = CryptoService();
  
  // Test me 12 fjalët
  print('📋 TESTI ME 12 FJALËT:');
  print('----------------------');
  final testMnemonic12 = "wise pigeon convince pelican dismiss upper social gift motor clutch caught word";
  final wallet12 = crypto.mnemonicToWallet(testMnemonic12, WarthogConstants.correctPath);
  print('Expected address: ${WarthogConstants.testAddress12}');
  print('Got address     : ${wallet12['address']}');
  print('Result: ${wallet12['address'] == WarthogConstants.testAddress12 ? '✅ PËRPUTHET' : '❌ NUK PËRPUTHET'}\n');
  
  // Test me 24 fjalët
  print('📋 TESTI ME 24 FJALËT:');
  print('----------------------');
  final testMnemonic24 = "cliff scare amused obscure method detail cross pole noodle sign flower camera dragon funny rabbit diesel mention twelve distance excess syrup organ among gown";
  final wallet24 = crypto.mnemonicToWallet(testMnemonic24, WarthogConstants.correctPath);
  print('Expected address: ${WarthogConstants.testAddress24}');
  print('Got address     : ${wallet24['address']}');
  print('Result: ${wallet24['address'] == WarthogConstants.testAddress24 ? '✅ PËRPUTHET' : '❌ NUK PËRPUTHET'}\n');
  
  // Krijo një portofol të ri
  print('🆕 KRIJIMI I NJË PORTOFOLI TË RI:');
  print('----------------------------------');
  final newWallet = crypto.createNewWallet(wordCount: 12);
  print('Mnemonic: ${newWallet['mnemonic']}');
  print('Address : ${newWallet['address']}');
  print('Path    : ${newWallet['derivationPath']}');
}