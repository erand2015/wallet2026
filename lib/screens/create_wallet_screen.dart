// lib/screens/create_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_service.dart';
import '../utils/constants.dart';
import '../theme/theme.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  int _wordCount = 12;      // 12 ose 24
  int _pathType = 0;        // 0 = Non-Hardened, 1 = Hardened
  bool _isLoading = false;
  Map<String, dynamic>? _createdWallet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Create Wallet'),
        elevation: 0,
      ),
      body: _createdWallet == null ? _buildForm() : _buildWalletDisplay(),
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
              'Create New Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Choose your wallet settings',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),

          // 1. Word Count
          const Text(
            'Word Count',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildWordOption(12, '12 Words')),
              const SizedBox(width: 12),
              Expanded(child: _buildWordOption(24, '24 Words')),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Derivation Path
          const Text(
            'Derivation Path',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
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

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save your seed phrase! If you lose it, you lose access to your wallet.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Create Button
          ElevatedButton(
            onPressed: _isLoading ? null : _createWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF25C05),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildWordOption(int count, String label) {
    final isSelected = _wordCount == count;
    return GestureDetector(
      onTap: () => setState(() => _wordCount = count),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF25C05) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade800),
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
              Text(label, style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
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
    final words = _createdWallet!['mnemonic'].split(' ');
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
                      const Text('Wallet Created!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        '${_wordCount} words • ${_pathType == 0 ? "Non-Hardened" : "Hardened"}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Seed Phrase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          const Text('Your Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _createdWallet!['address'],
              style: const TextStyle(color: Color(0xFFF25C05), fontSize: 12, fontFamily: 'monospace'),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _createdWallet!['mnemonic']));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                  },
                  child: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createWallet() async {
    setState(() => _isLoading = true);
    try {
      final walletService = WalletService();
      final path = _pathType == 0 ? WarthogConstants.nonHardenedPath : WarthogConstants.hardenedPath;
      final wallet = await walletService.createNewWallet(wordCount: _wordCount, derivationPath: path);
      setState(() {
        _createdWallet = {
          'mnemonic': wallet.mnemonic,
          'address': wallet.address,
          'privateKey': wallet.privateKey,
        };
        _isLoading = false;
      });
      await Provider.of<WalletProvider>(context, listen: false).loadWallet();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
