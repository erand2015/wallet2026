// lib/widgets/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/transaction.dart';
import '../theme/theme.dart';

class TransactionList extends StatelessWidget {
  final bool isPrivacyMode;

  const TransactionList({
    super.key,
    this.isPrivacyMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final transactions = transactionProvider.transactions;

    if (transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade800,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              color: WarthogColors.primaryYellow.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No transactions yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: Color(0xFF2A2A2A),
          ),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isReceived = tx.to == walletProvider.wallet?.address;
            
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isReceived 
                      ? WarthogColors.primaryYellow.withOpacity(0.1)
                      : WarthogColors.primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isReceived 
                      ? WarthogColors.primaryYellow 
                      : WarthogColors.primaryOrange,
                  size: 20,
                ),
              ),
              title: Text(
                isReceived ? 'Received' : 'Sent',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                _formatDate(tx.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isPrivacyMode 
                        ? '******' 
                        : '${isReceived ? '+' : '-'}${tx.amount.toStringAsFixed(4)} WART',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isReceived 
                          ? WarthogColors.primaryYellow 
                          : Colors.white,
                    ),
                  ),
                  Text(
                    isPrivacyMode 
                        ? '******' 
                        : '≈ \$${(tx.amount * 0.15).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours == 1) {
      return '1 hour ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}