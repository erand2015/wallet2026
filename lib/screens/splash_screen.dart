// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/theme.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    
    // Ngarko të dhënat dhe kalo te MainScreen
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Ngarko portofolin pa notify gjatë build
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.loadWallet(notify: false);
    
    // Ngarko transaksionet
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.loadTransactions();
    
    // Prisni 2 sekonda për animacion
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Kalo te MainScreen pa buton Back
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo rrethore me gradient
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF25C05), Color(0xFFFDB913)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF25C05).withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🐗',
                          style: TextStyle(
                            fontSize: 80,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Teksti WARTHOG
                    const Text(
                      'WARTHOG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Teksti WALLET
                    Text(
                      'WALLET',
                      style: TextStyle(
                        color: WarthogColors.primaryOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          WarthogColors.primaryOrange,
                        ),
                        strokeWidth: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Teksti i ngarkimit
                    Text(
                      'Loading wallet...',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}