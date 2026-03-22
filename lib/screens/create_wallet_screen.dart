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
  int _wordCount = 12; // 12 ose 24
  bool _useHardened = false; // false = Non-Hardened, true = Hardened
  bool _isLoading = false;
  Map<String, dynamic>? _createdWallet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Create Wallet',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: _createdWallet == null ? _buildForm() : _buildWalletDisplay(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Titull
          const Text(
            'Choose seed phrase length',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Opsionet 12/24 fjalë
          Row(
            children: [
              Expanded(
                child: _buildModernWordCountOption(12),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernWordCountOption(24),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Derivation Path Selection
          const Text(
            'Derivation Path Type',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildPathOption(
                  value: false,
                  title: 'Non-Hardened',
                  subtitle: 'm/44/2070/0/0/0',
                  description: 'Standard path, compatible with most wallets',
                  isSelected: !_useHardened,
                ),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                _buildPathOption(
                  value: true,
                  title: 'Hardened',
                  subtitle: "m/44'/2070'/0'/0'/0'",
                  description: 'More secure, used by official Warthog wallet',
                  isSelected: _useHardened,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Shpjegim
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: WarthogColors.primaryYellow.withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Your seed phrase is the key to your wallet. '
              'Write it down and store it in a safe place. '
              'Never share it with anyone!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Butoni i krijimit
          ElevatedButton(
            onPressed: _isLoading ? null : _createWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: WarthogColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Generate Seed Phrase',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernWordCountOption(int count) {
    final isSelected = _wordCount == count;
    
    return GestureDetector(
      onTap: () => setState(() => _wordCount = count),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    WarthogColors.primaryOrange,
                    WarthogColors.primaryYellow,
                  ],
                )
              : null,
          color: isSelected ? null : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.grey.shade800,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: WarthogColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'words',
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathOption({
    required bool value,
    required String title,
    required String subtitle,
    required String description,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _useHardened = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? WarthogColors.primaryOrange : Colors.grey.shade600,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarthogColors.primaryOrange,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? WarthogColors.primaryOrange : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
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
          // Success Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Created Successfully!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_wordCount} words • ${_useHardened ? "Hardened" : "Non-Hardened"}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Seed Phrase Title
          const Text(
            'Your Seed Phrase',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Seed Phrase Grid
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
                crossAxisCount: 3,
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

          const SizedBox(height: 16),

          // Address
          const Text(
            'Your Address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: SelectableText(
              _createdWallet!['address'],
              style: const TextStyle(
                color: WarthogColors.primaryOrange,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Path Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Derivation Path: ${_useHardened ? "m/44\'/2070\'/0\'/0\'/0\'" : "m/44/2070/0/0/0"}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Write these words down and keep them safe! '
                    'If you lose them, you lose access to your wallet.',
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

          // Buttons
          Row(
            children: [
              // Copy button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: _createdWallet!['mnemonic']
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Seed phrase copied!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy,
                    color: WarthogColors.primaryYellow,
                    size: 18,
                  ),
                  label: Text(
                    'Copy',
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
              
              // Go to Wallet button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarthogColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Wallet'),
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
      
      // Përdor path-in e duhur sipas përzgjedhjes
      final path = _useHardened 
          ? WarthogConstants.hardenedPath 
          : WarthogConstants.nonHardenedPath;
      
      final wallet = await walletService.createNewWallet(
        wordCount: _wordCount,
        derivationPath: path,
      );
      
      setState(() {
        _createdWallet = {
          'mnemonic': wallet.mnemonic,
          'address': wallet.address,
          'privateKey': wallet.privateKey,
        };
        _isLoading = false;
      });
      
      // Ruaj portofolin në provider
      final provider = Provider.of<WalletProvider>(context, listen: false);
      await provider.loadWallet();
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
