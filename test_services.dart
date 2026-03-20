import 'lib/services/wallet_service.dart';
import 'lib/utils/constants.dart';

void main() async {
  print('🧪 TESTIMI I WALLET SERVICE');
  print('===========================\n');
  
  final walletService = WalletService();
  
  // Testo krijimin e ri
  print('📌 Krijimi i portofolit të ri:');
  final newWallet = await walletService.createNewWallet(wordCount: 12);
  print('  Address: ${newWallet.address}');
  print('  Path: ${newWallet.derivationPath}');
  
  // Testo importin me 12 fjalët e tua
  print('\n📌 Importi me 12 fjalët:');
  final testMnemonic12 = "wise pigeon convince pelican dismiss upper social gift motor clutch caught word";
  final wallet12 = await walletService.importFromMnemonic(testMnemonic12);
  print('  Expected: ${WarthogConstants.testAddress12}');
  print('  Got: ${wallet12.address}');
  print('  Match: ${wallet12.address == WarthogConstants.testAddress12 ? '✅' : '❌'}');
  
  // Testo importin me 24 fjalët
  print('\n📌 Importi me 24 fjalët:');
  final testMnemonic24 = "cliff scare amused obscure method detail cross pole noodle sign flower camera dragon funny rabbit diesel mention twelve distance excess syrup organ among gown";
  final wallet24 = await walletService.importFromMnemonic(testMnemonic24);
  print('  Expected: ${WarthogConstants.testAddress24}');
  print('  Got: ${wallet24.address}');
  print('  Match: ${wallet24.address == WarthogConstants.testAddress24 ? '✅' : '❌'}');
  
  // Testo balancën
  print('\n📌 Kontrollo balancën:');
  final balance = await walletService.refreshBalance();
  print('  Balance: $balance WART');
}