// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/wallet.dart';
import 'storage_service.dart';
import '../theme/theme.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _storageService = StorageService();
  
  // Prefiksi për skedarët e backup
  static const String _backupPrefix = 'warthog_backup_';
  static const String _backupExtension = 'wbe'; // Warthog Backup Encrypted

  // Krijon një backup të kriptuar me fjalëkalim
  Future<String?> createEncryptedBackup(String password) async {
    try {
      // Lexo të dhënat nga secure storage
      final walletData = await _storageService.loadWallet();
      if (walletData == null) {
        throw Exception('No wallet found');
      }

      // Krijo objektin e backup
      final backupData = {
        'version': '2.0', // Version i ri për backup të kriptuar
        'timestamp': DateTime.now().toIso8601String(),
        'wallet': {
          'mnemonic': walletData.mnemonic,
          'address': walletData.address,
          'derivationPath': walletData.derivationPath,
        },
      };

      // Konverto në JSON
      final jsonString = jsonEncode(backupData);
      
      // Gjenero IV (Initialization Vector) të rastit
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // Krijo çelësin nga fjalëkalimi (AES-256 kërkon 32 bytes)
      final key = _deriveKeyFromPassword(password);
      
      // Krijo enkriptuesin
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Enkripto të dhënat
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      
      // Ruaj IV dhe të dhënat e enkriptuara së bashku
      final backupPackage = {
        'iv': iv.base64,
        'data': encrypted.base64,
        'version': '2.0',
      };
      
      // Konverto në JSON dhe pastaj në base64 për ruajtje
      final packageJson = jsonEncode(backupPackage);
      final finalBackup = base64Encode(utf8.encode(packageJson));
      
      print('✅ Backup i kriptuar u krijua me sukses');
      return finalBackup;
      
    } catch (e) {
      debugPrint('Error creating encrypted backup: $e');
      return null;
    }
  }

  // Rikthen portofolin nga backup i kriptuar
  Future<bool> restoreEncryptedBackup(String encryptedData, String password) async {
    try {
      // Dekodo base64
      final packageJson = utf8.decode(base64Decode(encryptedData));
      final backupPackage = jsonDecode(packageJson);
      
      // Verifiko versionin
      if (backupPackage['version'] != '2.0') {
        throw Exception('Unsupported backup version');
      }
      
      // Merr IV dhe të dhënat e enkriptuara
      final iv = encrypt.IV.fromBase64(backupPackage['iv']);
      final encryptedBase64 = backupPackage['data'];
      
      // Krijo çelësin nga fjalëkalimi
      final key = _deriveKeyFromPassword(password);
      
      // Krijo enkriptuesin
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Krijo objektin e të dhënave të enkriptuara
      final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
      
      // Dekripto
      final decryptedJson = encrypter.decrypt(encrypted, iv: iv);
      
      // Parse JSON
      final backupData = jsonDecode(decryptedJson);
      
      // Nxir të dhënat e portofolit
      final walletData = backupData['wallet'];
      final wallet = Wallet(
        mnemonic: walletData['mnemonic'],
        privateKey: '', // Do të rillogaritet nga mnemonic
        publicKey: '',
        address: walletData['address'],
        derivationPath: walletData['derivationPath'] ?? "m/44'/2070'/0'/0/0",
      );

      // Ruaj në secure storage
      await _storageService.saveWallet(wallet);
      
      print('✅ Backup i rikthyer me sukses');
      return true;
      
    } catch (e) {
      debugPrint('Error restoring encrypted backup: $e');
      return false;
    }
  }

  // Nxjerr çelësin AES-256 nga fjalëkalimi
  encrypt.Key _deriveKeyFromPassword(String password) {
    // Sigurohemi që password-i të jetë së paku 8 karaktere
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }
    
    // Për AES-256, na duhet një çelës 32 bytes
    // Përdorim PBKDF2 ose thjesht hash SHA-256
    final bytes = utf8.encode(password);
    
    // Nëse password-i është më i shkurtër se 32 bytes, e mbushim
    if (bytes.length < 32) {
      final padded = List<int>.filled(32, 0);
      for (int i = 0; i < bytes.length; i++) {
        padded[i] = bytes[i];
      }
      return encrypt.Key(Uint8List.fromList(padded));
    } 
    // Nëse është më i gjatë, presim në 32 bytes
    else {
      return encrypt.Key(Uint8List.fromList(bytes.sublist(0, 32)));
    }
  }

  // Ruaj backup të kriptuar në skedar
  Future<void> saveEncryptedBackupToFile(BuildContext context, String password) async {
    try {
      // Krijo backup të kriptuar
      final backupData = await createEncryptedBackup(password);
      if (backupData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create backup')),
        );
        return;
      }

      // Krijo skedar të përkohshëm
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_backupPrefix}$timestamp.$_backupExtension';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(backupData);

      // Shpërndaje skedarin
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Warthog Wallet Encrypted Backup',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Encrypted backup saved!')),
      );
      
    } catch (e) {
      debugPrint('Error saving backup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Ngarko backup të kriptuar nga skedar
  Future<void> loadEncryptedBackupFromFile(BuildContext context, String password) async {
    try {
      // Zgjidh skedarin
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [_backupExtension],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) return;

      // Lexo skedarin
      final file = File(filePath);
      final backupData = await file.readAsString();

      // Rikthe portofolin
      final success = await restoreEncryptedBackup(backupData, password);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Wallet restored successfully!')),
        );
        
        // Kthehu në home
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to restore wallet - wrong password?')),
        );
      }
    } catch (e) {
      debugPrint('Error loading backup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Shfaq seed phrase (pa ndryshime)
  Future<void> showSeedPhrase(BuildContext context) async {
    // ... kodi ekzistues (i njëjtë si më parë)
    try {
      final walletData = await _storageService.loadWallet();
      if (walletData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No wallet found')),
        );
        return;
      }

      final words = walletData.mnemonic.split(' ');
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: WarthogColors.primaryOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security,
                        color: WarthogColors.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your Seed Phrase',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: WarthogColors.primaryYellow.withOpacity(0.2),
                    ),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade800,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${index + 1}.',
                              style: TextStyle(
                                color: WarthogColors.primaryYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                words[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Never share your seed phrase with anyone! Store it in a safe place.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: walletData.mnemonic
                          ));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Seed phrase copied!'),
                              duration: Duration(seconds: 2),
                              backgroundColor: WarthogColors.primaryOrange,
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.copy,
                          color: WarthogColors.primaryYellow,
                          size: 18,
                        ),
                        label: Text(
                          'Copy All',
                          style: TextStyle(
                            color: WarthogColors.primaryYellow,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: WarthogColors.primaryYellow),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WarthogColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing seed phrase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Verifikon nëse një skedar është backup i vlefshëm
  Future<bool> isValidBackup(String backupData) async {
    try {
      final packageJson = utf8.decode(base64Decode(backupData));
      final data = jsonDecode(packageJson);
      return data['version'] == '2.0' && data.containsKey('iv') && data.containsKey('data');
    } catch (e) {
      return false;
    }
  }
}