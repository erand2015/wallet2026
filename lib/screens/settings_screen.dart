// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/backup_service.dart';
import '../services/biometric_service.dart';
import '../theme/theme.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    final hasPin = await _biometricService.hasPin();
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _hasPin = hasPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // ========== WALLET SECTION ==========
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Wallet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WarthogColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: WarthogColors.primaryOrange,
                size: 24,
              ),
            ),
            title: const Text(
              'Address',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: SelectableText(
              walletProvider.address.isNotEmpty 
                  ? walletProvider.address 
                  : 'No wallet loaded',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          
          // Show Seed Phrase Button
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WarthogColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.key,
                color: WarthogColors.primaryYellow,
                size: 24,
              ),
            ),
            title: const Text(
              'Show Seed Phrase',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'View your wallet seed phrase',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () async {
              final backupService = BackupService();
              await backupService.showSeedPhrase(context);
            },
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          
          // Logout Button
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              'Remove wallet from device',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () async {
              await walletProvider.logout();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          
          const SizedBox(height: 20),
          
          // ========== SECURITY SECTION ==========
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Security',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Biometric Authentication (Face ID / Touch ID)
          if (_biometricAvailable)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WarthogColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: WarthogColors.primaryYellow,
                  size: 24,
                ),
              ),
              title: const Text(
                'Face ID / Touch ID',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Use biometrics to unlock wallet',
                style: TextStyle(color: Colors.white70),
              ),
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Kërko autentikim para aktivizimit
                    final auth = await _biometricService.authenticateWithBiometrics();
                    if (auth) {
                      await _biometricService.setBiometricEnabled(true);
                      setState(() {
                        _biometricEnabled = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Face ID enabled')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Authentication failed')),
                      );
                    }
                  } else {
                    await _biometricService.setBiometricEnabled(false);
                    setState(() {
                      _biometricEnabled = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Face ID disabled')),
                    );
                  }
                },
                activeColor: WarthogColors.primaryOrange,
              ),
            ),
          
          // PIN Code
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WarthogColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.pin,
                color: WarthogColors.primaryYellow,
                size: 24,
              ),
            ),
            title: const Text(
              'PIN Code',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Set a PIN to secure your wallet',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasPin)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                IconButton(
                  icon: Icon(
                    _hasPin ? Icons.edit : Icons.add,
                    color: WarthogColors.primaryYellow,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PinScreen(
                          isSetup: true,
                          onSuccess: () {
                            setState(() {
                              _hasPin = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN set successfully')),
                            );
                          },
                        ),
                      ),
                    );
                    _loadSecuritySettings();
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          
          const SizedBox(height: 20),
          
          // ========== BACKUP & RESTORE SECTION ==========
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Backup & Restore',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Backup Button (Encrypted)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WarthogColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock,
                color: WarthogColors.primaryOrange,
                size: 24,
              ),
            ),
            title: const Text(
              'Encrypted Backup',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Save wallet with password protection',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () => _showEncryptedBackupDialog(context),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          
          // Restore Button (Encrypted)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: WarthogColors.primaryYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_open,
                color: WarthogColors.primaryYellow,
                size: 24,
              ),
            ),
            title: const Text(
              'Restore Encrypted',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Restore from password-protected backup',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () => _showEncryptedRestoreDialog(context),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          
          const SizedBox(height: 20),
          
          // ========== NETWORK SECTION ==========
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Network',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.link,
                color: Colors.blue,
                size: 24,
              ),
            ),
            title: const Text(
              'Node URL',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'http://217.182.64.43:3001',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          
          const SizedBox(height: 20),
          
          // ========== ABOUT SECTION ==========
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info,
                color: Colors.purple,
                size: 24,
              ),
            ),
            title: const Text(
              'Version',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              '1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEncryptedBackupDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Encrypted Backup',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set a strong password to encrypt your wallet backup',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  hintText: 'Enter password',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  hintText: 'Re-enter password',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Password must be at least 8 characters',
                style: TextStyle(
                  color: WarthogColors.primaryYellow,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              final confirm = confirmController.text;
              
              if (password.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters')),
                );
                return;
              }
              
              if (password != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              Navigator.pop(context);
              final backupService = BackupService();
              await backupService.saveEncryptedBackupToFile(context, password);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WarthogColors.primaryOrange,
            ),
            child: const Text('CREATE BACKUP'),
          ),
        ],
      ),
    );
  }

  void _showEncryptedRestoreDialog(BuildContext context) {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Restore Encrypted Backup',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the password used to encrypt the backup file',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  hintText: 'Enter password',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WarthogColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: WarthogColors.primaryYellow.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: WarthogColors.primaryYellow,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will be prompted to select a .wbe backup file after entering the password',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter password')),
                );
                return;
              }
              Navigator.pop(context);
              final backupService = BackupService();
              await backupService.loadEncryptedBackupFromFile(context, password);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: WarthogColors.primaryOrange,
            ),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );
  }
}