import 'lib/services/wallet_service.dart';
import 'lib/utils/constants.dart';

void main() async {
  print('🧪 TESTIMI I NGARKIMIT TË PORTOFOLIT');
  print('=====================================\n');
  
  final walletService = WalletService();
  
  // Provoni të ngarkoni portofolin
  print('📌 Ngarkimi i portofolit nga storage:');
  final wallet = await walletService.loadWallet();
  
  if (wallet != null) {
    print('✅ Portofoli u ngarkua me sukses!');
    print('   Address: ${wallet.address}');
    print('   Private Key: ${wallet.privateKey.substring(0, 16)}...');
    print('   Balance: ${wallet.balance} WART');
  } else {
    print('❌ Nuk u gjet asnjë portofol i ruajtur.');
    print('\n📌 Ju lutem importoni portofolin tuaj nga aplikacioni.');
  }
  
  // Shfaq adresën që dihet se ka monedha
  print('\n📌 Adresa me monedha e njohur:');
  print('   ${WarthogConstants.yourRealAddress}');
}