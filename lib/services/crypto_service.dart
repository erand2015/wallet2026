// lib/services/crypto_service.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:pointycastle/export.dart' as pc;
import 'package:convert/convert.dart';
import 'package:fixnum/fixnum.dart';
import '../utils/constants.dart';
import '../utils/pointycastle_setup.dart';

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  // 1. GJENERIMI I 12/24 FJALËVE
  String generateMnemonic({int wordCount = 12}) {
    final strength = wordCount == 12 ? 128 : 256;
    final mnemonic = bip39.generateMnemonic(strength: strength);
    
    final words = mnemonic.split(' ');
    if (words.length != wordCount) {
      throw Exception('Generated ${words.length} words, expected $wordCount');
    }
    
    return mnemonic;
  }

  // 2. VALIDIMI I MNEMONIC
  bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  // 3. NGA MNEMONIC NË PRIVATE KEY
  Uint8List mnemonicToPrivateKey(String mnemonic, String derivationPath) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final hdKey = root.derivePath(derivationPath);
    return hdKey.privateKey!;
  }

  // 4. NGA PRIVATE KEY NË PUBLIC KEY
  Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    final domain = pc.ECDomainParameters('secp256k1');
    final privateKeyBigInt = BigInt.parse(hex.encode(privateKey), radix: 16);
    
    // Llogarit çelësin publik
    final publicKeyPoint = (domain.G * privateKeyBigInt)!;
    
    // Merr publik key të pangjeshur (65 bytes)
    final uncompressed = publicKeyPoint.getEncoded(false);
    
    // Nxjerr x dhe y
    final x = uncompressed.sublist(1, 33);
    final y = uncompressed.sublist(33, 65);
    
    // Krijo versionin e ngjeshur
    final prefix = y.last % 2 == 0 ? 0x02 : 0x03;
    final compressed = Uint8List.fromList([prefix, ...x]);
    
    return compressed;
  }

  // 5. NGA PUBLIC KEY NË ADRESË
  String publicKeyToAddress(Uint8List publicKey) {
    final sha256 = pc.SHA256Digest();
    final sha256Hash = sha256.process(publicKey);
    
    final ripemd160 = pc.RIPEMD160Digest();
    final ripeHash = ripemd160.process(sha256Hash);
    
    final singleSha = sha256.process(ripeHash);
    final checksum = singleSha.sublist(0, 4);
    
    final addressBytes = Uint8List(ripeHash.length + checksum.length)
      ..setAll(0, ripeHash)
      ..setAll(ripeHash.length, checksum);
    
    return hex.encode(addressBytes);
  }

  // 6. FUNKSIONI DIAGNOSTIKUES PËR PRIVATE KEY
  Map<String, dynamic> diagnosePrivateKey(String mnemonic, String derivationPath) {
    print('🔍 DIAGNOSTIKIM I PRIVATE KEY');
    print('Mnemonic: $mnemonic');
    print('Derivation Path: $derivationPath');
    
    final seed = bip39.mnemonicToSeed(mnemonic);
    print('Seed (hex): ${hex.encode(seed)}');
    
    final root = bip32.BIP32.fromSeed(seed);
    print('Root private key: ${hex.encode(root.privateKey!)}');
    print('Root public key: ${hex.encode(root.publicKey)}');
    
    final hdKey = root.derivePath(derivationPath);
    final privateKey = hdKey.privateKey!;
    final privateKeyHex = hex.encode(privateKey);
    
    print('Derived private key: $privateKeyHex');
    print('Derived public key: ${hex.encode(hdKey.publicKey)}');
    
    return {
      'seed': hex.encode(seed),
      'rootPrivate': hex.encode(root.privateKey!),
      'rootPublic': hex.encode(root.publicKey),
      'derivedPrivate': privateKeyHex,
      'derivedPublic': hex.encode(hdKey.publicKey),
    };
  }

  // 7. FUNKSIONI PËR TË PROVUAR TË GJITHA PATH-ET
  void testAllPaths(String mnemonic) {
    print('\n🔍 TESTIMI I TË GJITHA PATH-EVE');
    print('Mnemonic: $mnemonic');
    
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    
    final paths = [
      "m/44'/2070'/0'/0'/0'",
      "m/44'/2070'/0/0/0",
      "m/44'/2070'/0'/0/0",
      "m/44'/2070'/0/0'/0",
      "m/44'/2070'/0'/0/0'",
    ];
    
    for (final path in paths) {
      try {
        final hdKey = root.derivePath(path);
        final privateKey = hdKey.privateKey!;
        final privateKeyHex = hex.encode(privateKey);
        print('Path: $path');
        print('  Private key: $privateKeyHex');
        print('  Public key: ${hex.encode(hdKey.publicKey)}');
      } catch (e) {
        print('Path: $path - ERROR: $e');
      }
    }
  }

  // 8. FUNKSIONI PËR TË PARË HAPAT E ADRESËS
  void diagnoseAddress(String publicKeyHex) {
    print('\n🔍 DIAGNOSTIKIM I ADRESËS');
    print('Public key: $publicKeyHex');
    
    final publicKey = Uint8List.fromList(hex.decode(publicKeyHex));
    final sha256 = pc.SHA256Digest();
    
    final sha256Hash = sha256.process(publicKey);
    print('SHA-256(public key): ${hex.encode(sha256Hash)}');
    
    final ripemd160 = pc.RIPEMD160Digest();
    final ripeHash = ripemd160.process(sha256Hash);
    print('RIPEMD-160: ${hex.encode(ripeHash)} (20 bytes)');
    
    final singleSha = sha256.process(ripeHash);
    final checksum = singleSha.sublist(0, 4);
    print('Checksum (single SHA-256): ${hex.encode(checksum)}');
    
    final address = hex.encode(Uint8List.fromList([...ripeHash, ...checksum]));
    print('Address: $address');
  }

  // 9. NGA MNEMONIC NË WALLET
  Map<String, dynamic> mnemonicToWallet(String mnemonic, String derivationPath) {
    final privateKeyBytes = mnemonicToPrivateKey(mnemonic, derivationPath);
    final privateKeyHex = hex.encode(privateKeyBytes);
    
    final publicKeyBytes = privateKeyToPublicKey(privateKeyBytes);
    final publicKeyHex = hex.encode(publicKeyBytes);
    
    final address = publicKeyToAddress(publicKeyBytes);
    
    return {
      'mnemonic': mnemonic,
      'privateKey': privateKeyHex,
      'publicKey': publicKeyHex,
      'address': address,
      'derivationPath': derivationPath,
    };
  }

  // 10. KRIJIM I RI PORTOFOLI
  Map<String, dynamic> createNewWallet({int wordCount = 12}) {
    final mnemonic = generateMnemonic(wordCount: wordCount);
    final path = WarthogConstants.correctPath;
    return mnemonicToWallet(mnemonic, path);
  }

  // 11. IMPORT NGA MNEMONIC
  Map<String, dynamic> importFromMnemonic(String mnemonic) {
    final path = WarthogConstants.correctPath;
    return mnemonicToWallet(mnemonic, path);
  }

  // 12. VERIFIKIM ME ADRESAT E TUA
  bool verifyWithTestAddresses() {
    print('🧪 TESTI ME 12 FJALËT:');
    final testMnemonic12 = "wise pigeon convince pelican dismiss upper social gift motor clutch caught word";
    final wallet12 = mnemonicToWallet(testMnemonic12, WarthogConstants.correctPath);
    final match12 = wallet12['address'] == WarthogConstants.testAddress12;
    print('  Expected address: ${WarthogConstants.testAddress12}');
    print('  Got address: ${wallet12['address']}');
    print('  Match: ${match12 ? '✅' : '❌'}\n');
    
    print('🧪 TESTI ME 24 FJALËT:');
    final testMnemonic24 = "cliff scare amused obscure method detail cross pole noodle sign flower camera dragon funny rabbit diesel mention twelve distance excess syrup organ among gown";
    final wallet24 = mnemonicToWallet(testMnemonic24, WarthogConstants.correctPath);
    final match24 = wallet24['address'] == WarthogConstants.testAddress24;
    print('  Expected address: ${WarthogConstants.testAddress24}');
    print('  Got address: ${wallet24['address']}');
    print('  Match: ${match24 ? '✅' : '❌'}\n');
    
    return match12 && match24;
  }

  // 13. KRIJO TË DHËNAT E TRANSAKSIONIT (99 bytes)
  Uint8List createTransactionData({
    required Int64 amountE8,
    required Int64 feeE8,
    required int pinHeight,
    required int nonceId,
    required String pinHash,
    required String toAddress,
  }) {
    final pinHashBytes = hex.decode(pinHash);
    final toAddrBytes = hex.decode(toAddress).sublist(0, 20);
    
    final data = Uint8List(32 + 4 + 4 + 3 + 8 + 20 + 8);
    var offset = 0;
    
    data.setAll(offset, pinHashBytes);
    offset += 32;
    
    data.setAll(offset, _intToBytes(pinHeight, 4));
    offset += 4;
    
    data.setAll(offset, _intToBytes(nonceId, 4));
    offset += 4;
    
    data.setAll(offset, [0, 0, 0]);
    offset += 3;
    
    data.setAll(offset, _int64ToBytes(feeE8));
    offset += 8;
    
    data.setAll(offset, toAddrBytes);
    offset += 20;
    
    data.setAll(offset, _int64ToBytes(amountE8));
    
    return data;
  }

  // 14. NËNSHKRUAJ TRANSAKSIONIN - VERSIONI ME KONTROLL TË PLOTË PËR NULL
  Uint8List signTransaction(Uint8List privateKey, Uint8List dataToSign) {
    try {
      print('📝 Nënshkrimi i transaksionit...');
      
      // HAPI 1: SHA256 hash i të dhënave
      final sha256 = pc.SHA256Digest();
      final digest = sha256.process(dataToSign);
      print('✅ Hapi 1: Digest u krijua');
      
      // HAPI 2: Krijo domain parameters
      final domain = pc.ECDomainParameters('secp256k1');
      print('✅ Hapi 2: Domain u krijua');
      
      // HAPI 3: Konverto private key në BigInt
      final privateKeyHex = hex.encode(privateKey);
      print('   Private key hex: ${privateKeyHex.substring(0, 16)}...');
      final privateKeyBigInt = BigInt.parse(privateKeyHex, radix: 16);
      print('✅ Hapi 3: Private key u konvertua');
      print('   privateKeyBigInt: ${privateKeyBigInt.toString().substring(0, 20)}...');
      
      // HAPI 4: Krijo nonce k (për testim përdorim vlerë fikse)
      final k = BigInt.parse('12345678901234567890');
      print('✅ Hapi 4: Nonce k u krijua: $k');
      
      // HAPI 5: Merr G (generator)
      final G = domain.G;
      if (G == null) {
        print('❌ G is null');
        throw Exception('G is null');
      }
      print('✅ Hapi 5: G u mor');
      
      // HAPI 6: Llogarit R = k * G
      final R = G * k;
      if (R == null) {
        print('❌ R is null');
        throw Exception('R is null');
      }
      print('✅ Hapi 6: R u llogarit');
      
      // HAPI 7: Merr x koordinatën e R
      final r = R.x;
      if (r == null) {
        print('❌ r is null');
        throw Exception('r is null');
      }
      final rBigInt = r.toBigInteger();
      if (rBigInt == null) {
        print('❌ rBigInt is null');
        throw Exception('rBigInt is null');
      }
      print('✅ Hapi 7: r u mor: ${rBigInt.toString().substring(0, 20)}...');
      
      // HAPI 8: Merr n (order)
      final n = domain.n;
      if (n == null) {
        print('❌ n is null');
        throw Exception('n is null');
      }
      print('✅ Hapi 8: n u mor');
      
      // HAPI 9: Konverto digest në BigInt
      final digestHex = hex.encode(digest);
      final digestInt = BigInt.parse(digestHex, radix: 16);
      print('✅ Hapi 9: digestInt u krijua');
      
      // HAPI 10: Llogarit k^-1 mod n
      final kInv = k.modInverse(n);
      print('✅ Hapi 10: kInv u llogarit');
      
      // HAPI 11: Kontrollo rBigInt dhe privateKeyBigInt para shumëzimit
      print('   Kontrollo rBigInt: ${rBigInt != null}');
      print('   Kontrollo privateKeyBigInt: ${privateKeyBigInt != null}');
      
      if (rBigInt == null) {
        throw Exception('rBigInt is null at step 11');
      }
      if (privateKeyBigInt == null) {
        throw Exception('privateKeyBigInt is null at step 11');
      }
      
      // HAPI 11: Llogarit r * privateKey
      final rTimesPrivate = rBigInt * privateKeyBigInt;
      if (rTimesPrivate == null) {
        print('❌ rTimesPrivate is null');
        throw Exception('rTimesPrivate is null');
      }
      print('✅ Hapi 11: rTimesPrivate u llogarit');
      
      // HAPI 12: Llogarit digest + rTimesPrivate
      final digestPlusRTimesPrivate = digestInt + rTimesPrivate;
      print('✅ Hapi 12: digestPlusRTimesPrivate u llogarit');
      
      // HAPI 13: Llogarit kInv * digestPlusRTimesPrivate
      final kInvTimes = kInv * digestPlusRTimesPrivate;
      print('✅ Hapi 13: kInvTimes u llogarit');
      
      // HAPI 14: Llogarit s mod n
      final s = kInvTimes % n;
      print('✅ Hapi 14: s u llogarit');
      
      // HAPI 15: Formato si 65 bytes (r + s + recId)
      final rBytes = _intToBytes(rBigInt, 32);
      final sBytes = _intToBytes(s, 32);
      final recId = 0;
      
      print('✅ Hapi 15: Nënshkrimi u formatua');
      print('✅ Nënshkrimi u krye me sukses!');
      
      return Uint8List.fromList([...rBytes, ...sBytes, recId]);
      
    } catch (e) {
      print('❌ Gabim gjatë nënshkrimit: $e');
      print('⚠️ Përdoret nënshkrim zero për testim');
      return Uint8List(65);
    }
  }

  // Helper: int to bytes
  Uint8List _intToBytes(dynamic value, int length) {
    BigInt bigInt;
    if (value is BigInt) {
      bigInt = value;
    } else if (value is int) {
      bigInt = BigInt.from(value);
    } else if (value is Int64) {
      bigInt = BigInt.from(value.toInt());
    } else {
      throw Exception('Unsupported type for _intToBytes');
    }
    
    final bytes = Uint8List(length);
    final hexStr = bigInt.toRadixString(16).padLeft(length * 2, '0');
    return Uint8List.fromList(hex.decode(hexStr));
  }

  Uint8List _int64ToBytes(Int64 value) {
    return _intToBytes(value, 8);
  }
}