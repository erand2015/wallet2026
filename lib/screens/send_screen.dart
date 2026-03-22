// lib/screens/send_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/wallet_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/transaction.dart';
import '../theme/theme.dart';
import 'dart:developer' as developer;

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController(text: '0.01');
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  double? _minFee;

  @override
  void initState() {
    super.initState();
    _loadMinFee();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WalletProvider>(context, listen: false);
      if (provider.wallet == null) {
        provider.loadWallet();
      }
    });
  }

  Future<void> _loadMinFee() async {
    try {
      final apiService = ApiService();
      final minFee = await apiService.getMinimumFee();
      setState(() {
        _minFee = minFee;
      });
    } catch (e) {
      print('Error loading min fee: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final wallet = walletProvider.wallet;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('Send WART'),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              if (wallet != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF25C05).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Balance:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${wallet.balance.toStringAsFixed(8)} WART',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF25C05),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'No wallet loaded. Please import a wallet first.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Success Message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Recipient Address
              const Text(
                'Recipient Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _toController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Enter WART address (48 hex characters)',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF25C05), width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              // Amount with MAX button - DECIMAL KEYBOARD
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) => _calculateRemaining(),
                      onEditingComplete: () {
                        FocusScope.of(context).nextFocus();
                      },
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFF25C05), width: 2),
                        ),
                        suffixText: 'WART',
                        suffixStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          WarthogColors.primaryOrange,
                          WarthogColors.primaryYellow,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _setMaxAmount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'MAX',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Fee - DECIMAL KEYBOARD
              const Text(
                'Network Fee',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  _calculateRemaining();
                  setState(() {});
                },
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: '0.01',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF25C05), width: 2),
                  ),
                  suffixText: 'WART',
                  suffixStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 4),
              
              // Minimum fee indicator
              if (_minFee != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isFeeValid() ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isFeeValid() ? Icons.check_circle : Icons.info_outline,
                        color: _isFeeValid() ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isFeeValid() 
                            ? '✓ Fee is valid (min: $_minFee WART)'
                            : '⚠ Fee too low! Minimum: $_minFee WART',
                          style: TextStyle(
                            color: _isFeeValid() ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Remaining balance
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  final wallet = walletProvider.wallet;
                  if (wallet == null) return const SizedBox.shrink();
                  
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  final fee = double.tryParse(_feeController.text) ?? 0.01;
                  final total = amount + fee;
                  final remaining = wallet.balance - total;
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: remaining < 0 
                          ? Colors.red.withOpacity(0.1)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: remaining < 0
                            ? Colors.red.withOpacity(0.3)
                            : Colors.grey.shade800,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: remaining < 0
                                  ? Colors.red
                                  : WarthogColors.primaryYellow,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remaining after transaction:',
                              style: TextStyle(
                                color: remaining < 0
                                    ? Colors.red
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${remaining.toStringAsFixed(6)} WART',
                          style: TextStyle(
                            color: remaining < 0
                                ? Colors.red
                                : remaining < 0.1
                                    ? WarthogColors.primaryYellow
                                    : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Send Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (wallet == null || _isLoading || !_isFeeValid()) ? null : _sendTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF25C05),
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
                          'Send Transaction',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Cancel Button
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFeeValid() {
    if (_minFee == null) return true;
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    return fee >= _minFee!;
  }

  void _calculateRemaining() {
    setState(() {});
  }

  void _setMaxAmount() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final wallet = walletProvider.wallet;
    if (wallet == null) return;
    
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    final maxAmount = (wallet.balance - fee).clamp(0, wallet.balance);
    
    setState(() {
      _amountController.text = maxAmount.toStringAsFixed(6);
    });
    
    _calculateRemaining();
  }

  void _sendTransaction() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    final toAddress = _toController.text.trim();
    if (toAddress.isEmpty || toAddress.length != 48 || !RegExp(r'^[0-9a-fA-F]{48}$').hasMatch(toAddress)) {
      setState(() {
        _isLoading = false;
        _errorMessage = '❌ Invalid address format (must be 48 hex characters)';
      });
      return;
    }
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = '❌ Invalid amount';
      });
      return;
    }
    
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    if (_minFee != null && fee < _minFee!) {
      setState(() {
        _isLoading = false;
        _errorMessage = '❌ Fee too low! Minimum fee is $_minFee WART';
      });
      return;
    }
    
    try {
      final walletService = WalletService();
      final txId = await walletService.sendTransaction(
        toAddress: toAddress,
        amount: amount,
        fee: fee,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = '✅ Transaction sent!\nTXID: ${txId.substring(0, 16)}...';
        });
        
        try {
          final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
          final walletProvider = Provider.of<WalletProvider>(context, listen: false);
          
          final newTx = Transaction(
            txId: txId,
            from: walletProvider.wallet!.address,
            to: toAddress,
            amount: amount,
            fee: fee,
            timestamp: DateTime.now(),
            status: TransactionStatus.pending,
          );
          
          await transactionProvider.addTransaction(newTx);
          
          Future.delayed(const Duration(seconds: 30), () async {
            try {
              await transactionProvider.updateTransactionStatus(txId, TransactionStatus.confirmed);
            } catch (e) {
              print('Gabim gjatë përditësimit të statusit: $e');
            }
          });
        } catch (e) {
          print('Gabim gjatë ruajtjes së transaksionit: $e');
        }
        
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        await walletProvider.refreshBalance();
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    super.dispose();
  }
}
