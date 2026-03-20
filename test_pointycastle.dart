import 'package:pointycastle/export.dart';
import 'dart:math';
import 'dart:typed_data';
import 'lib/utils/pointycastle_setup.dart';

void main() {
  print('🧪 TESTIMI I POINTYCASTLE');
  print('=========================\n');
  
  // Inicializo PointyCastle
  setupPointyCastle();
  
  print('\n📋 TESTET INDIVIDUALE:');
  print('----------------------\n');
  
  // Test 1: SHA256
  try {
    final sha256 = SHA256Digest();
    final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
    
    // Update me tre parametra
    sha256.update(testData, 0, testData.length);
    
    // Krijo buffer për rezultatin
    final hash = Uint8List(sha256.digestSize);
    sha256.doFinal(hash, 0);  // doFinal kthen int, por hash mbushet
    
    print('✅ SHA256 punon: hash = ${_bytesToHex(hash)}');
  } catch (e) {
    print('❌ SHA256 problem: $e');
  }
  
  // Test 2: RIPEMD160
  try {
    final ripemd160 = RIPEMD160Digest();
    final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
    
    ripemd160.update(testData, 0, testData.length);
    
    final hash = Uint8List(ripemd160.digestSize);
    ripemd160.doFinal(hash, 0);
    
    print('✅ RIPEMD160 punon: hash = ${_bytesToHex(hash)}');
  } catch (e) {
    print('❌ RIPEMD160 problem: $e');
  }
  
  // Test 3: SecureRandom
  try {
    final random = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    random.seed(KeyParameter(Uint8List.fromList(seeds)));
    final bytes = random.nextBytes(16);
    print('✅ FortunaRandom punon: ${_bytesToHex(bytes)}');
  } catch (e) {
    print('❌ FortunaRandom problem: $e');
  }
  
  // Test 4: ECDSA domain
  try {
    final domain = ECDomainParameters('secp256k1');
    final g = domain.G;
    print('✅ secp256k1 domain punon');
    if (g != null) {
      print('   Generator: (${g.x!.toBigInteger()}, ${g.y!.toBigInteger()})');
    }
  } catch (e) {
    print('❌ secp256k1 problem: $e');
  }
  
  // Test 5: ECDSA signer
  try {
    final signer = ECDSASigner();
    print('✅ ECDSASigner u krijua');
  } catch (e) {
    print('❌ ECDSASigner problem: $e');
  }
}

String _bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}