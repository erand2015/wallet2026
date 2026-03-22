// lib/screens/import_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';
import '../utils/constants.dart';
import '../theme/theme.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _mnemonicController = TextEditingController();
  int _pathType = 0;        // 0 = Non-Hardened, 1 = Hardened
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _importedWallet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Import Wallet'),
        elevation: 0,
      ),
      body: _importedWallet == null ? _buildForm() : _buildWalletDisplay(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titulli
          const Center(
            child: Text(
              'Import Wallet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Enter your 12 or 24 word seed phrase',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),

          // Seed Phrase Input
          const Text('Seed Phrase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _mnemonicController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'Enter your seed phrase...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste, color: WarthogColors.primaryYellow),
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Derivation Path
          const Text('Derivation Path', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPathOption(0, 'Non-Hardened', 'm/44/2070/0/0/0'),
                _buildPathOption(1, 'Hardened', "m/44'/2070'/0'/0'/0'"),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Import Button
          ElevatedButton(
            onPressed: _isLoading ? null : _importWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25C05),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Import Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildPathOption(int value, String title, String path) {
    final isSelected = _pathType == value;
    return GestureDetector(
      onTap: () => setState(() => _pathType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFF25C05) : Colors.grey.shade600, width: 2),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF25C05)),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? const Color(0xFFF25C05) : Colors.white)),
                  Text(path, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletDisplay() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wallet Imported!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        _pathType == 0 ? 'Non-Hardened Path' : 'Hardened Path',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Your Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _importedWallet!['address'],
              style: const TextStyle(color: Color(0xFFF25C05), fontSize: 12, fontFamily: 'monospace'),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Balance', style: TextStyle(color: Colors.grey.shade400)),
                Text(
                  '${_importedWallet!['balance']?.toStringAsFixed(4) ?? '0'} WART',
                  style: const TextStyle(color: Color(0xFFF25C05), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _importedWallet = null;
                      _mnemonicController.clear();
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<WalletProvider>(context, listen: false).loadWallet();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Go to Wallet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() => _mnemonicController.text = data!.text!.trim());
    }
  }

  Future<void> _importWallet() async {
    final mnemonic = _mnemonicController.text.trim();
    if (mnemonic.isEmpty) {
      setState(() => _errorMessage = 'Please enter your seed phrase');
      return;
    }

    final words = mnemonic.split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) {
      setState(() => _errorMessage = 'Must be 12 or 24 words (found ${words.length})');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final walletService = WalletService();
      final path = _pathType == 0 ? WarthogConstants.nonHardenedPath : WarthogConstants.hardenedPath;
      final wallet = await walletService.importFromMnemonic(mnemonic, path);
      final balance = await walletService.getBalance(wallet['address']);

      setState(() {
        _importedWallet = {
          'address': wallet['address'],
          'privateKey': wallet['privateKey'],
          'balance': balance,
        };
        _isLoading = false;
      });

      await Provider.of<WalletProvider>(context, listen: false).loadWallet();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }
}
