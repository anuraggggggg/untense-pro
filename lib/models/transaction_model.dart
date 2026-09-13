enum TransactionType { earning, payout }

enum TransactionStatus { pending, completed, failed }

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? upiId;
  final String description;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.upiId,
    required this.description,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] == 'payout'
          ? TransactionType.payout
          : TransactionType.earning,
      status: _parseStatus(map['status']),
      upiId: map['upiId'],
      description: map['description'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'upiId': upiId,
      'description': description,
      'timestamp': timestamp,
    };
  }

  static TransactionStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }
}
