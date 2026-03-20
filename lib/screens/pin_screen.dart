// lib/screens/pin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/biometric_service.dart';
import '../providers/wallet_provider.dart';
import '../theme/theme.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup; // Nëse është setup i PIN-it të ri
  final VoidCallback? onSuccess;
  
  const PinScreen({
    super.key,
    this.isSetup = false,
    this.onSuccess,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final BiometricService _biometricService = BiometricService();
  String _pin = '';
  String _confirmPin = '';
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: Text(widget.isSetup ? 'Set PIN' : 'Enter PIN'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikona
            Icon(
              widget.isSetup ? Icons.lock_outline : Icons.lock,
              size: 60,
              color: WarthogColors.primaryYellow,
            ),
            const SizedBox(height: 20),
            
            // Titulli
            Text(
              widget.isSetup 
                  ? 'Create a PIN code' 
                  : 'Enter your PIN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Nëntitull
            Text(
              widget.isSetup
                  ? 'PIN will be used to secure your wallet'
                  : 'Enter your 4-6 digit PIN',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            
            // Fushat e PIN-it
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Fusha e parë (PIN)
                  TextField(
                    obscureText: true,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: widget.isSetup ? 'Enter PIN' : 'PIN',
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _pin = value;
                        _errorMessage = '';
                      });
                    },
                  ),
                  
                  // Fusha e dytë (Konfirmim) - vetëm për setup
                  if (widget.isSetup) ...[
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: true,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirm PIN',
                        labelStyle: TextStyle(color: Colors.grey.shade500),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _confirmPin = value;
                          _errorMessage = '';
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            
            // Gabimi
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            const SizedBox(height: 30),
            
            // Butoni i veprimit
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: WarthogColors.primaryOrange,
                minimumSize: const Size(double.infinity, 50),
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
                  : Text(
                      widget.isSetup ? 'Set PIN' : 'Unlock',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    
    if (widget.isSetup) {
      // Setup PIN i ri
      if (_pin.length < 4) {
        setState(() {
          _errorMessage = 'PIN must be at least 4 digits';
          _isLoading = false;
        });
        return;
      }
      
      if (_pin != _confirmPin) {
        setState(() {
          _errorMessage = 'PINs do not match';
          _isLoading = false;
        });
        return;
      }
      
      await _biometricService.savePin(_pin);
      await _biometricService.setPinEnabled(true);
      
      if (mounted) {
        Navigator.pop(context);
        if (widget.onSuccess != null) widget.onSuccess!();
      }
    } else {
      // Verifikimi i PIN-it
      final isValid = await _biometricService.verifyPin(_pin);
      
      if (isValid) {
        if (mounted) {
          Navigator.pop(context);
          if (widget.onSuccess != null) widget.onSuccess!();
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN';
          _pin = '';
          _isLoading = false;
        });
      }
    }
  }
}