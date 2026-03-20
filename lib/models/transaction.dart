// lib/models/transaction.dart
class Transaction {
  final String txId;
  final String from;
  final String to;
  final double amount;
  final double fee;
  final DateTime timestamp;
  final TransactionStatus status;
  
  Transaction({
    required this.txId,
    required this.from,
    required this.to,
    required this.amount,
    required this.fee,
    required this.timestamp,
    required this.status,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      txId: json['txId'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      fee: json['fee']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.pending,
      ),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'txId': txId,
      'from': from,
      'to': to,
      'amount': amount,
      'fee': fee,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}

enum TransactionStatus {
  pending,
  confirmed,
  failed,
}