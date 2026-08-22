enum TransactionType {
  send,
  receive,
  swap,
  approval,
  contractCall,
}

enum TransactionStatus {
  success,
  pending,
  failed,
}

class TransactionRecord {
  final String txHash;
  final String fromAddress;
  final String toAddress;
  final double amount;
  final String symbol;
  final DateTime timestamp;
  final TransactionStatus status;
  final TransactionType type;
  final String networkId;
  final String? explorerUrl;
  final String? fee;

  const TransactionRecord({
    required this.txHash,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.symbol,
    required this.timestamp,
    this.status = TransactionStatus.success,
    this.type = TransactionType.send,
    required this.networkId,
    this.explorerUrl,
    this.fee,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      txHash: json['txHash'] ?? '',
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      symbol: json['symbol'] ?? 'POL',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.success,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.send,
      ),
      networkId: json['networkId'] ?? 'polygon',
      explorerUrl: json['explorerUrl'],
      fee: json['fee'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'txHash': txHash,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'amount': amount,
      'symbol': symbol,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'type': type.name,
      'networkId': networkId,
      'explorerUrl': explorerUrl,
      'fee': fee,
    };
  }
}
