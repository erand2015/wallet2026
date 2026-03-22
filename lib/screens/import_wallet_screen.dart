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
  final _verifyAddressController = TextEditingController();
  
  int _importMode = 0;      // 0 = Manual, 1 = Auto-detect
  int _selectedManualPath = 0; // 0 = Hardened, 1 = Non-Hardened
  
  bool _isLoading = false;
  bool _isDetecting = false;
  String? _errorMessage;
  Map<String, dynamic>? _selectedWallet;
  
  // Për auto-detect
  List<Map<String, dynamic>> _detectedPaths = [];
  int? _selectedPathIndex;
  bool _showVerifyField = false;

  @override
  void dispose() {
    _mnemonicController.dispose();
    _verifyAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Import Wallet',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: _selectedWallet == null ? _buildForm() : _buildWalletDisplay(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Titull
          const Text(
            'Enter your seed phrase',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Nëntitull
          const Text(
            '12 or 24 words',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Fusha e tekstit
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _errorMessage != null
                    ? Colors.red.withOpacity(0.5)
                    : Colors.grey.shade800,
              ),
            ),
            child: TextField(
              controller: _mnemonicController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'Enter your 12 or 24 word seed phrase...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.paste,
                    color: WarthogColors.primaryYellow,
                  ),
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
          ),
          
          // Mesazh gabimi
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // ========== DERIVATION PATH SELECTION ==========
          const Text(
            'Derivation Path',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Manual option
                _buildRadioOption(
                  value: 0,
                  groupValue: _importMode,
                  title: 'I know my path (select manually)',
                  subtitle: 'Fast import - choose the path you used',
                  onChanged: (v) {
                    setState(() {
                      _importMode = v;
                      _detectedPaths.clear();
                      _selectedPathIndex = null;
                      _errorMessage = null;
                    });
                  },
                ),
                
                if (_importMode == 0) ...[
                  const Divider(color: Color(0xFF2A2A2A), height: 1),
                  _buildManualPathOption(
                    value: 0,
                    groupValue: _selectedManualPath,
                    title: 'Hardened',
                    path: "m/44'/2070'/0'/0'/0'",
                    onChanged: (v) => setState(() => _selectedManualPath = v),
                  ),
                  _buildManualPathOption(
                    value: 1,
                    groupValue: _selectedManualPath,
                    title: 'Non-Hardened',
                    path: 'm/44/2070/0/0/0',
                    onChanged: (v) => setState(() => _selectedManualPath = v),
                  ),
                ],
                
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                
                // Auto-detect option
                _buildRadioOption(
                  value: 1,
                  groupValue: _importMode,
                  title: 'Auto-detect',
                  subtitle: 'Try both paths and show balances (slower)',
                  onChanged: (v) {
                    setState(() {
                      _importMode = v;
                      if (_importMode == 1 && _mnemonicController.text.trim().isNotEmpty) {
                        _autoDetectPaths(_mnemonicController.text.trim());
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Loading indicator for auto-detect
          if (_isDetecting)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WarthogColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WarthogColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detecting wallet type...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          
          // Detected paths (for auto-detect mode)
          if (_importMode == 1 && _detectedPaths.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Select your wallet type:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ..._detectedPaths.asMap().entries.map((entry) => 
                    _buildDetectedPathTile(entry.key, entry.value)
                  ),
                  
                  // Verification field (only if both have 0 balance)
                  if (_showVerifyField)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Color(0xFF2A2A2A)),
                          const SizedBox(height: 12),
                          const Text(
                            'Verify your address:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _verifyAddressController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your Warthog address',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: WarthogColors.primaryOrange),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your address to verify the correct wallet type',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Butoni i importit
          ElevatedButton(
            onPressed: _isLoading || _isDetecting ? null : _importWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: WarthogColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade800,
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
                    'Import Wallet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          
          const SizedBox(height: 12),
          
          // Butoni kthehu
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required int value,
    required int groupValue,
    required String title,
    required String subtitle,
    required Function(int) onChanged,
  }) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
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
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarthogColors.primaryOrange,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
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
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
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

  Widget _buildManualPathOption({
    required int value,
    required int groupValue,
    required String title,
    required String path,
    required Function(int) onChanged,
  }) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
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
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarthogColors.primaryOrange,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
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
                  Text(
                    path,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontFamily: 'monospace',
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

  Widget _buildDetectedPathTile(int index, Map<String, dynamic> path) {
    final isSelected = _selectedPathIndex == index;
    final hasBalance = (path['balance'] ?? 0) > 0;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPathIndex = index;
          if (hasBalance) {
            _showVerifyField = false;
          } else {
            _showVerifyField = true;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? WarthogColors.primaryOrange.withOpacity(0.1) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade800),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
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
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WarthogColors.primaryOrange,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        path['name'],
                        style: TextStyle(
                          color: hasBalance ? Colors.white : Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasBalance)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (!hasBalance && path['balance'] == 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'No Activity',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    path['path'],
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Address: ${path['address'].substring(0, 16)}...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (hasBalance)
                    Text(
                      'Balance: ${path['balance']?.toStringAsFixed(4) ?? '0'} WART',
                      style: TextStyle(
                        color: WarthogColors.primaryOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
                        'Wallet Imported Successfully!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedWallet!['name'] ?? 
                        (_selectedManualPath == 0 ? 'Hardened' : 'Non-Hardened'),
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
              _selectedWallet!['address'],
              style: const TextStyle(
                color: WarthogColors.primaryOrange,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Balance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_selectedWallet!['balance']?.toStringAsFixed(4) ?? '0'} WART',
                  style: const TextStyle(
                    color: WarthogColors.primaryOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Path Info
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Derivation Path: ${_selectedWallet!['path']}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedWallet = null;
                      _detectedPaths.clear();
                      _selectedPathIndex = null;
                      _showVerifyField = false;
                      _mnemonicController.clear();
                      _verifyAddressController.clear();
                      _errorMessage = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final walletProvider = Provider.of<WalletProvider>(
                      context,
                      listen: false,
                    );
                    await walletProvider.loadWallet();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarthogColors.primaryOrange,
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

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null && clipboardData.text != null) {
        setState(() {
          _mnemonicController.text = clipboardData.text!.trim();
          _errorMessage = null;
        });
        
        // Nëse është në auto-detect dhe fjalët janë futur, fillo auto-detect
        if (_importMode == 1 && _mnemonicController.text.trim().isNotEmpty) {
          _autoDetectPaths(_mnemonicController.text.trim());
        }
      }
    } catch (e) {
      debugPrint('Error pasting: $e');
    }
  }

  Future<void> _autoDetectPaths(String mnemonic) async {
    setState(() {
      _isDetecting = true;
      _detectedPaths.clear();
      _errorMessage = null;
    });
    
    final walletService = WalletService();
    final paths = [
      {'name': 'Hardened', 'path': WarthogConstants.hardenedPath},
      {'name': 'Non-Hardened', 'path': WarthogConstants.nonHardenedPath},
    ];
    
    List<Map<String, dynamic>> results = [];
    
    for (var p in paths) {
      try {
        final wallet = await walletService.importFromMnemonic(mnemonic, p['path']);
        final balance = await walletService.getBalance(wallet['address']);
        
        results.add({
          'name': p['name'],
          'path': p['path'],
          'address': wallet['address'],
          'privateKey': wallet['privateKey'],
          'balance': balance,
        });
      } catch (e) {
        results.add({
          'name': p['name'],
          'path': p['path'],
          'address': 'Error',
          'privateKey': '',
          'balance': -1,
        });
      }
    }
    
    // Sort by balance (highest first)
    results.sort((a, b) => (b['balance'] ?? 0).compareTo(a['balance'] ?? 0));
    
    // Kontrollo nëse ndonjëra ka balance
    final hasBalance = results.any((r) => (r['balance'] ?? 0) > 0);
    
    setState(() {
      _detectedPaths = results;
      _isDetecting = false;
      
      if (hasBalance) {
        // Zgjedh automatikisht atë me balance
        _selectedPathIndex = 0;
        _showVerifyField = false;
      } else {
        // Nuk ka balance, përdoruesi duhet të zgjedhë dhe verifikojë
        _showVerifyField = true;
      }
    });
  }

  Future<void> _importWallet() async {
    final mnemonic = _mnemonicController.text.trim();
    
    // Validim bazë
    if (mnemonic.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your seed phrase';
      });
      return;
    }

    final words = mnemonic.split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) {
      setState(() {
        _errorMessage = 'Seed phrase must be 12 or 24 words (found ${words.length})';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final walletService = WalletService();
      Map<String, dynamic> wallet;
      
      if (_importMode == 0) {
        // ========== MANUAL MODE ==========
        final path = _selectedManualPath == 0 
            ? WarthogConstants.hardenedPath 
            : WarthogConstants.nonHardenedPath;
        
        wallet = await walletService.importFromMnemonic(mnemonic, path);
        final balance = await walletService.getBalance(wallet['address']);
        wallet['balance'] = balance;
        wallet['name'] = _selectedManualPath == 0 ? 'Hardened' : 'Non-Hardened';
        
        // Nëse balance është 0, paralajmëro përdoruesin
        if (balance == 0) {
          final confirmed = await _showZeroBalanceWarning(wallet);
          if (!confirmed) {
            setState(() => _isLoading = false);
            return;
          }
        }
        
        setState(() {
          _selectedWallet = wallet;
          _isLoading = false;
        });
        
      } else {
        // ========== AUTO-DETECT MODE ==========
        if (_detectedPaths.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          await _autoDetectPaths(mnemonic);
          return;
        }
        
        if (_selectedPathIndex == null) {
          setState(() {
            _errorMessage = 'Please select a wallet type';
            _isLoading = false;
          });
          return;
        }
        
        final selected = _detectedPaths[_selectedPathIndex!];
        
        // Nëse nuk ka balance, verifiko adresën
        if ((selected['balance'] ?? 0) == 0 && _showVerifyField) {
          final enteredAddress = _verifyAddressController.text.trim();
          if (enteredAddress.isEmpty) {
            setState(() {
              _errorMessage = 'Please enter your address to verify';
              _isLoading = false;
            });
            return;
          }
          
          if (enteredAddress != selected['address']) {
            setState(() {
              _errorMessage = 'Address does not match. Please check and try again.';
              _isLoading = false;
            });
            return;
          }
        }
        
        setState(() {
          _selectedWallet = selected;
          _isLoading = false;
        });
      }
      
      // Ruaj portofolin në provider
      final provider = Provider.of<WalletProvider>(context, listen: false);
      await provider.loadWallet();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Future<bool> _showZeroBalanceWarning(Map<String, dynamic> wallet) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Warning', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This wallet has 0 balance.',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Address: ${wallet['address'].substring(0, 24)}...',
              style: TextStyle(
                color: WarthogColors.primaryOrange,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If this is not the correct wallet, your funds may be lost.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: WarthogColors.primaryOrange,
            ),
            child: const Text('Import Anyway'),
          ),
        ],
      ),
    ) ?? false;
  }
}
