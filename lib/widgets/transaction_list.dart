// lib/widgets/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart'; // Ndrysho këtu!
import '../providers/wallet_provider.dart';
import '../models/transaction.dart';
import '../theme/theme.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final transactions = transactionProvider.transactions;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 8),
              Text(
                'Your transactions will appear here',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
            
            // Ngjyra bazuar në status
            Color statusColor = Colors.grey;
            if (tx.status == TransactionStatus.confirmed) {
              statusColor = Colors.green;
            } else if (tx.status == TransactionStatus.pending) {
              statusColor = WarthogColors.primaryYellow;
            } else if (tx.status == TransactionStatus.failed) {
              statusColor = Colors.red;
            }
            
            return ListTile(
              leading: Stack(
                children: [
                  Container(
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
                  if (tx.status != TransactionStatus.confirmed)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Text(
                    isReceived ? 'Received' : 'Sent',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (tx.status == TransactionStatus.pending)
                    const Text(
                      '(pending)',
                      style: TextStyle(
                        color: WarthogColors.primaryYellow,
                        fontSize: 12,
                      ),
                    ),
                  if (tx.status == TransactionStatus.failed)
                    const Text(
                      '(failed)',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                ],
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
                    '${isReceived ? '+' : '-'}${tx.amount.toStringAsFixed(4)} WART',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isReceived 
                          ? WarthogColors.primaryYellow 
                          : Colors.white,
                    ),
                  ),
                  Text(
                    '≈ \$${(tx.amount * 0.15).toStringAsFixed(2)}',
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