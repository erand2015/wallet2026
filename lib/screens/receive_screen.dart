// lib/screens/receive_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/wallet_provider.dart';
import '../theme/theme.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context).wallet;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Background i zi
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text(
          'Receive WART',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Code - MË I MADH DHE MË I QARTË
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // Sfond i bardhë për QR (që të duket mirë)
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: WarthogColors.primaryOrange.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: wallet?.address ?? 'No address',
                  version: QrVersions.auto,
                  size: 250.0, // Më i madh për lexim më të lehtë
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.H, // Më i saktë
                ),
              ),
              
              const SizedBox(height: 30),
              
              // "Your Address" tekst
              const Text(
                'Your Address',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Adresa në sfond gri të errët (jo të bardhë!)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A), // Gri i errët
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WarthogColors.primaryYellow.withOpacity(0.3),
                  ),
                ),
                child: SelectableText(
                  wallet?.address ?? 'No wallet loaded',
                  style: const TextStyle(
                    color: Colors.white, // Tekst i bardhë
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Butoni Copy
              ElevatedButton.icon(
                onPressed: () {
                  if (wallet != null) {
                    Clipboard.setData(ClipboardData(text: wallet.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Address copied to clipboard!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: WarthogColors.primaryOrange,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text(
                  'Copy Address',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WarthogColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Udhëzim për përdoruesin
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: WarthogColors.primaryYellow.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'Scan this QR code with your mobile wallet to receive WART',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}