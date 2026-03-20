// 1. GJENERIMI I 12/24 FJALËVE (BIP39)
String generateMnemonic({int wordCount = 12}) {
  final strength = wordCount == 12 ? 128 : 256;
  
  // Metoda e saktë për bip39 paketën
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

// 3. NGA MNEMONIC NË PRIVATE KEY (BIP32 + Derivation Path)
Uint8List mnemonicToPrivateKey(String mnemonic, String derivationPath) {
  // BIP39: nga mnemonic në seed (512 bit)
  final seed = bip39.mnemonicToSeed(mnemonic);
  
  // BIP32: nga seed në private key përmes derivation path
  final root = bip32.BIP32.fromSeed(seed);
  final hdKey = root.derivePath(derivationPath);
  
  return hdKey.privateKey!;
}

// 4. NGA PRIVATE KEY NË PUBLIC KEY (Compressed - 33 bytes)
Uint8List privateKeyToPublicKey(Uint8List privateKey) {
  // Krijo parametrat e curves secp256k1
  final domain = pc.ECDomainParameters('secp256k1');
  
  // Krijo private key object
  final privateKeyBigInt = BigInt.parse(hex.encode(privateKey), radix: 16);
  final privateKeyObj = pc.ECPrivateKey(privateKeyBigInt, domain);
  
  // Nxirr çelësin publik - KORIGJUAR!
  final publicKeyObj = privateKeyObj.publicKey as pc.ECPublicKey;
  final publicKeyBytes = publicKeyObj.Q!.getEncoded(false);
  
  // Ngjesh çelësin publik (33 bytes)
  final x = publicKeyBytes.sublist(1, 33);
  final y = publicKeyBytes.sublist(33, 65);
  final prefix = y.last % 2 == 0 ? 0x02 : 0x03;
  
  return Uint8List.fromList([prefix, ...x]);
}

// 5. NGA PUBLIC KEY NË ADRESËN WARTHOG
String publicKeyToAddress(Uint8List publicKey) {
  // Hapi 1: SHA-256 e public key
  final sha256 = pc.SHA256Digest();
  final sha256Hash = sha256.process(publicKey);
  
  // Hapi 2: RIPEMD-160 e SHA-256 hash
  final ripemd160 = pc.RIPEMD160Digest();
  final ripeHash = ripemd160.process(sha256Hash);
  
  // Hapi 3: Checksum (4 bytes)
  final doubleSha = sha256.process(sha256.process(ripeHash));
  final checksum = doubleSha.sublist(0, 4);
  
  // Hapi 4: Adresa përfundimtare
  final addressBytes = Uint8List(ripeHash.length + checksum.length)
    ..setAll(0, ripeHash)
    ..setAll(ripeHash.length, checksum);
  
  return hex.encode(addressBytes);
}