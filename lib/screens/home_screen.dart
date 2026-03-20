// lib/screens/home_screen.dart - Pjesa e initState
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/action_buttons.dart';
import '../widgets/transaction_list.dart';
import '../services/notification_service.dart';
import '../theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ngarko portofolin dhe transaksionet kur hapet ekrani
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      walletProvider.loadWallet();
      
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      transactionProvider.loadTransactions();
    });
  }

  // Pjesa tjetër e kodit mbetet e njëjtë...
}