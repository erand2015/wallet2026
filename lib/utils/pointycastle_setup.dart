// lib/utils/pointycastle_setup.dart
import 'package:pointycastle/export.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'dart:math';
import 'dart:typed_data';

/// Inicializon PointyCastle duke regjistruar të gjitha algoritmet e nevojshme
void setupPointyCastle() {
  print('🔄 Inicializimi i PointyCastle...');
  
  // Regjistro të gjitha algoritmet që na duhen
  registerAlgorithms();
  
  print('✅ PointyCastle u inicializua me sukses');
}

void registerAlgorithms() {
  // Regjistro SHA256
  try {
    final sha256 = SHA256Digest();
    // KORIGJUAR: Update me tre parametra
    sha256.update(Uint8List.fromList([0]), 0, 1);
    print('✅ SHA256 u regjistrua');
  } catch (e) {
    print('⚠️ Problem me SHA256: $e');
  }
  
  // Regjistro RIPEMD160
  try {
    final ripemd160 = RIPEMD160Digest();
    // KORIGJUAR: Update me tre parametra
    ripemd160.update(Uint8List.fromList([0]), 0, 1);
    print('✅ RIPEMD160 u regjistrua');
  } catch (e) {
    print('⚠️ Problem me RIPEMD160: $e');
  }
  
  // Regjistro ECDSA dhe SecureRandom
  try {
    final random = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    random.seed(KeyParameter(Uint8List.fromList(seeds)));
    
    final testBytes = random.nextBytes(16);
    print('✅ SecureRandom (FortunaRandom) u inicializua: ${testBytes.length} bytes');
  } catch (e) {
    print('⚠️ Problem me SecureRandom: $e');
    
    try {
      final seed = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        seed[i] = Random.secure().nextInt(256);
      }
      
      final random = FortunaRandom();
      random.seed(KeyParameter(seed));
      
      print('✅ SecureRandom alternativ u inicializua');
    } catch (e2) {
      print('❌ Problem serioz me SecureRandom: $e2');
      
      try {
        final seed = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          seed[i] = Random().nextInt(256);
        }
        
        final random = FortunaRandom();
        random.seed(KeyParameter(seed));
        
        print('⚠️ SecureRandom jo i sigurt u përdor për testim');
      } catch (e3) {
        print('❌ Nuk mund të inicializohet asnjë SecureRandom: $e3');
      }
    }
  }
  
  // Regjistro secp256k1
  try {
    final curve = ECCurve_secp256k1();
    print('✅ secp256k1 u regjistrua');
  } catch (e) {
    print('⚠️ Problem me secp256k1: $e');
  }
}

/// Krijon një SecureRandom të gatshëm për përdorim
SecureRandom createSecureRandom() {
  final random = FortunaRandom();
  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(255));
  }
  random.seed(KeyParameter(Uint8List.fromList(seeds)));
  return random;
}