class Token {
  final String id;
  final String networkId;
  final String symbol;
  final String name;
  final int decimals;
  final String? contractAddress; // null for native token
  final double priceUsd;
  final double change24h;
  final double balance;
  final double fiatValue;
  final bool isNative;
  final String? iconAsset;

  const Token({
    required this.id,
    required this.networkId,
    required this.symbol,
    required this.name,
    this.decimals = 18,
    this.contractAddress,
    this.priceUsd = 0.0,
    this.change24h = 0.0,
    this.balance = 0.0,
    this.fiatValue = 0.0,
    this.isNative = false,
    this.iconAsset,
  });

  Token copyWith({
    String? id,
    String? networkId,
    String? symbol,
    String? name,
    int? decimals,
    String? contractAddress,
    double? priceUsd,
    double? change24h,
    double? balance,
    double? fiatValue,
    bool? isNative,
    String? iconAsset,
  }) {
    return Token(
      id: id ?? this.id,
      networkId: networkId ?? this.networkId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      decimals: decimals ?? this.decimals,
      contractAddress: contractAddress ?? this.contractAddress,
      priceUsd: priceUsd ?? this.priceUsd,
      change24h: change24h ?? this.change24h,
      balance: balance ?? this.balance,
      fiatValue: fiatValue ?? this.fiatValue,
      isNative: isNative ?? this.isNative,
      iconAsset: iconAsset ?? this.iconAsset,
    );
  }

  String get formattedBalance {
    if (balance == 0) return '0';
    if (balance < 0.000001) return '<0.000001';
    if (balance >= 1000) {
      return balance.toStringAsFixed(2);
    } else if (balance >= 1) {
      return balance.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '');
    } else {
      return balance.toStringAsFixed(6).replaceAll(RegExp(r'\.?0+$'), '');
    }
  }

  String get formattedPrice {
    if (priceUsd >= 1000) {
      final parts = priceUsd.toStringAsFixed(2).split('.');
      final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '\$$whole.${parts[1]}';
    } else if (priceUsd >= 1) {
      return '\$${priceUsd.toStringAsFixed(2)}';
    } else if (priceUsd > 0) {
      return '\$${priceUsd.toStringAsFixed(4)}';
    } else {
      return '\$0.00';
    }
  }

  String get formattedFiat {
    if (fiatValue == 0) return r'$0.00';
    if (fiatValue < 0.01) return r'<$0.01';
    if (fiatValue >= 1000) {
      final parts = fiatValue.toStringAsFixed(2).split('.');
      final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '\$$whole.${parts[1]}';
    }
    return '\$${fiatValue.toStringAsFixed(2)}';
  }

  String get formattedChange {
    final prefix = change24h >= 0 ? '+' : '';
    return '$prefix${change24h.toStringAsFixed(2)}%';
  }

  bool get isPositiveChange => change24h >= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'networkId': networkId,
        'symbol': symbol,
        'name': name,
        'decimals': decimals,
        'contractAddress': contractAddress,
        'priceUsd': priceUsd,
        'change24h': change24h,
        'balance': balance,
        'fiatValue': fiatValue,
        'isNative': isNative,
        'iconAsset': iconAsset,
      };

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        id: json['id'] as String,
        networkId: json['networkId'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        decimals: json['decimals'] as int? ?? 18,
        contractAddress: json['contractAddress'] as String?,
        priceUsd: (json['priceUsd'] as num?)?.toDouble() ?? 0.0,
        change24h: (json['change24h'] as num?)?.toDouble() ?? 0.0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        fiatValue: (json['fiatValue'] as num?)?.toDouble() ?? 0.0,
        isNative: json['isNative'] as bool? ?? false,
        iconAsset: json['iconAsset'] as String?,
      );
}
