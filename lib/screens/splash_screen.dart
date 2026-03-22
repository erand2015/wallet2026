// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.loadWallet(notify: false);
    
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.loadTransactions();
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🐗', style: TextStyle(fontSize: 100)),
            SizedBox(height: 20),
            Text(
              'WARTHOG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              'WALLET',
              style: TextStyle(
                color: Color(0xFFF25C05),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF25C05)),
            ),
          ],
        ),
      ),
    );
  }
}