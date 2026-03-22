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

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> with SingleTickerProviderStateMixin {
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController(text: '0.01');
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  double? _minFee;
  double? _estimatedTotal;
  
  // Për animacion
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Për validim
  bool _isAddressValid = false;
  bool _isAmountValid = false;

  @override
  void initState() {
    super.initState();
    _loadMinFee();
    
    // Animacionet
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    // Listener për validim
    _toController.addListener(_validateAddress);
    _amountController.addListener(_validateAmount);
    _feeController.addListener(_updateEstimatedTotal);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WalletProvider>(context, listen: false);
      if (provider.wallet == null) {
        provider.loadWallet();
      }
    });
  }

  void _validateAddress() {
    final address = _toController.text.trim();
    final isValid = address.length == 48 && RegExp(r'^[0-9a-fA-F]{48}$').hasMatch(address);
    if (_isAddressValid != isValid) {
      setState(() => _isAddressValid = isValid);
    }
  }

  void _validateAmount() {
    final amount = double.tryParse(_amountController.text);
    final isValid = amount != null && amount > 0;
    if (_isAmountValid != isValid) {
      setState(() => _isAmountValid = isValid);
    }
    _updateEstimatedTotal();
  }
  
  void _updateEstimatedTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    setState(() {
      _estimatedTotal = amount + fee;
    });
  }

  Future<void> _loadMinFee() async {
    try {
      final apiService = ApiService();
      final minFee = await apiService.getMinimumFee();
      setState(() => _minFee = minFee);
    } catch (e) {
      print('Error loading min fee: $e');
    }
  }

  // DIALOG KONFIRMIMI PARA DËRGIMIT
  Future<void> _showConfirmDialog() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final wallet = walletProvider.wallet;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    final total = amount + fee;
    final remaining = (wallet?.balance ?? 0) - total;
    final toAddress = _toController.text.trim();
    final shortAddress = '${toAddress.substring(0, 8)}...${toAddress.substring(toAddress.length - 8)}';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: WarthogColors.primaryOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.send,
                  color: WarthogColors.primaryOrange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Confirm Transaction',
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFF2A2A2A), height: 20),
                
                // Recipient
                _buildConfirmRow(
                  icon: Icons.person_outline,
                  label: 'Recipient',
                  value: shortAddress,
                  valueColor: Colors.white70,
                ),
                const SizedBox(height: 16),
                
                // Amount
                _buildConfirmRow(
                  icon: Icons.attach_money,
                  label: 'Amount',
                  value: '$amount WART',
                  valueColor: WarthogColors.primaryOrange,
                  highlight: true,
                ),
                const SizedBox(height: 16),
                
                // Fee
                _buildConfirmRow(
                  icon: Icons.local_gas_station,
                  label: 'Network Fee',
                  value: '$fee WART',
                  valueColor: Colors.white70,
                ),
                
                const Divider(color: Color(0xFF2A2A2A), height: 24),
                
                // Total
                _buildConfirmRow(
                  icon: Icons.summarize,
                  label: 'Total',
                  value: '$total WART',
                  valueColor: Colors.white,
                  isTotal: true,
                ),
                
                const SizedBox(height: 16),
                
                // Remaining Balance
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: remaining < 0.01 
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        remaining < 0.01 ? Icons.warning_amber : Icons.account_balance_wallet,
                        color: remaining < 0.01 ? Colors.red : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Remaining after transaction:',
                          style: TextStyle(
                            color: remaining < 0.01 ? Colors.red.shade300 : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${remaining.toStringAsFixed(6)} WART',
                        style: TextStyle(
                          color: remaining < 0.01 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This transaction cannot be reversed. Please verify the address carefully.',
                          style: TextStyle(
                            color: Colors.orange.shade300,
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
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.grey.shade800,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendTransaction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarthogColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Send',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfirmRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool highlight = false,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (isTotal ? WarthogColors.primaryOrange : Colors.grey.shade800).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isTotal ? WarthogColors.primaryOrange : Colors.grey.shade400,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.grey.shade400,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: highlight || isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }

  // DIALOG SUKSESI I MADH
  void _showSuccessNotification(String txId, double amount, double fee, String toAddress) {
    final shortTxId = '${txId.substring(0, 16)}...${txId.substring(txId.length - 8)}';
    final shortAddress = '${toAddress.substring(0, 8)}...${toAddress.substring(toAddress.length - 8)}';
    final total = amount + fee;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animacion suksesi
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaction Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your transaction has been sent to the network',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Amount', '$amount WART', WarthogColors.primaryOrange),
                    const SizedBox(height: 8),
                    _buildDetailRow('Fee', '$fee WART', Colors.white70),
                    const Divider(color: Color(0xFF3A3A3A), height: 16),
                    _buildDetailRow('Total', '${total.toStringAsFixed(6)} WART', Colors.white, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipient',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortAddress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Transaction ID',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortTxId,
                      style: TextStyle(
                        color: WarthogColors.primaryOrange,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Mbyll dialogun
                        Navigator.pop(context); // Kthehu te HomeScreen
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.grey.shade800,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Kopjo TX ID në clipboard
                        // TODO: Implement clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction ID copied!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarthogColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Copy TX ID',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final wallet = walletProvider.wallet;
    
    final bool isFormValid = wallet != null &&
        _isAddressValid &&
        _isAmountValid &&
        _isFeeValid() &&
        !_isLoading;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            title: const Text('Send WART'),
            elevation: 0,
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card
                  if (wallet != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF2A2A2A),
                          ],
                        ),
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
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '${wallet.balance.toStringAsFixed(8)} WART',
                              key: ValueKey(wallet.balance),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF25C05),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Error/Success Messages
                  if (_errorMessage != null)
                    _buildMessageCard(_errorMessage!, Colors.red),
                  if (_successMessage != null)
                    _buildMessageCard(_successMessage!, Colors.green),
                  
                  const SizedBox(height: 20),
                  
                  // Recipient Address Field
                  const Text(
                    'Recipient Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF25C05), width: 2),
                      ),
                      suffixIcon: _toController.text.isNotEmpty
                          ? Icon(_isAddressValid ? Icons.check_circle : Icons.error, color: _isAddressValid ? Colors.green : Colors.red)
                          : null,
                    ),
                    maxLines: 2,
                  ),
                  if (_toController.text.isNotEmpty && !_isAddressValid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        'Address must be exactly 48 hexadecimal characters',
                        style: TextStyle(color: Colors.red.shade400, fontSize: 11),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Amount Field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFF25C05), width: 2),
                            ),
                            suffixText: 'WART',
                            suffixStyle: const TextStyle(color: Colors.white70),
                            suffixIcon: _amountController.text.isNotEmpty
                                ? Icon(_isAmountValid ? Icons.check_circle : Icons.error, color: _isAmountValid ? Colors.green : Colors.red)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [WarthogColors.primaryOrange, WarthogColors.primaryYellow],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _setMaxAmount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('MAX', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Fee Field
                  const Text('Network Fee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '0.01',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF25C05), width: 2),
                      ),
                      suffixText: 'WART',
                      suffixStyle: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  
                  // Fee indicator
                  if (_minFee != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isFeeValid() ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(_isFeeValid() ? Icons.check_circle : Icons.info_outline, color: _isFeeValid() ? Colors.green : Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _isFeeValid() ? '✓ Fee is valid (min: $_minFee WART)' : '⚠ Fee too low! Minimum: $_minFee WART',
                            style: TextStyle(color: _isFeeValid() ? Colors.green : Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary Card
                  if (_estimatedTotal != null && _estimatedTotal! > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Amount', '${_amountController.text} WART'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Fee', '${_feeController.text} WART'),
                          const Divider(color: Color(0xFF2A2A2A), height: 16),
                          _buildSummaryRow('Total', '${_estimatedTotal!.toStringAsFixed(6)} WART', isTotal: true),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Send Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFormValid ? _showConfirmDialog : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF25C05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Text('Send Transaction', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageCard(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_successMessage != null ? Icons.check_circle : Icons.error_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? Colors.white : Colors.grey.shade400, fontSize: isTotal ? 14 : 12)),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? WarthogColors.primaryOrange : Colors.white,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }

  bool _isFeeValid() {
    if (_minFee == null) return true;
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    return fee >= _minFee!;
  }

  void _setMaxAmount() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final wallet = walletProvider.wallet;
    if (wallet == null) return;
    
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    final maxAmount = (wallet.balance - fee).clamp(0, wallet.balance);
    
    setState(() {
      _amountController.text = maxAmount.toStringAsFixed(6);
      _isAmountValid = maxAmount > 0;
    });
    _updateEstimatedTotal();
  }

  void _sendTransaction() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    final toAddress = _toController.text.trim();
    final amount = double.tryParse(_amountController.text);
    final fee = double.tryParse(_feeController.text) ?? 0.01;
    
    if (amount == null || amount <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = '❌ Invalid amount';
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
        });
        
        // Shto transaksionin në histori
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
        
        // Zbritja nga balanca
        final currentBalance = walletProvider.wallet!.balance;
        final totalSpent = amount + fee;
        final newBalance = currentBalance - totalSpent;
        walletProvider.wallet!.balance = newBalance;
        
        // Rifresko balancën nga blockchain
        await walletProvider.refreshBalance();
        
        // 🔥 TREGO DIALOGUN E MADH TË SUKSESIT
        _showSuccessNotification(txId, amount, fee, toAddress);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '❌ ${e.toString().replaceAll('Exception: ', '')}';
        });
        
        // SnackBar për gabim
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _toController.removeListener(_validateAddress);
    _amountController.removeListener(_validateAmount);
    _feeController.removeListener(_updateEstimatedTotal);
    _toController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
