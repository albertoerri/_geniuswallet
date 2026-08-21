class MarketItem {
  final String id;
  final String symbol;
  final String name;
  final double priceUsd;
  final double change24h;
  final double volume24h;
  final double marketCap;
  final double high24h;
  final double low24h;
  final String category; // 'Layer 1', 'DeFi', 'Meme', 'AI', 'Layer 2', 'Infrastructure'
  final String networkId; // 'ethereum', 'polygon', 'bnb', 'solana', 'bitcoin', 'base'
  final String? contractAddress;
  final List<double> sparkline;
  final bool isFavorite;
  final int rank;

  const MarketItem({
    required this.id,
    required this.symbol,
    required this.name,
    required this.priceUsd,
    required this.change24h,
    required this.volume24h,
    required this.marketCap,
    required this.high24h,
    required this.low24h,
    required this.category,
    required this.networkId,
    this.contractAddress,
    required this.sparkline,
    this.isFavorite = false,
    required this.rank,
  });

  MarketItem copyWith({
    String? id,
    String? symbol,
    String? name,
    double? priceUsd,
    double? change24h,
    double? volume24h,
    double? marketCap,
    double? high24h,
    double? low24h,
    String? category,
    String? networkId,
    String? contractAddress,
    List<double>? sparkline,
    bool? isFavorite,
    int? rank,
  }) {
    return MarketItem(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      priceUsd: priceUsd ?? this.priceUsd,
      change24h: change24h ?? this.change24h,
      volume24h: volume24h ?? this.volume24h,
      marketCap: marketCap ?? this.marketCap,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      category: category ?? this.category,
      networkId: networkId ?? this.networkId,
      contractAddress: contractAddress ?? this.contractAddress,
      sparkline: sparkline ?? this.sparkline,
      isFavorite: isFavorite ?? this.isFavorite,
      rank: rank ?? this.rank,
    );
  }

  String get formattedPrice {
    if (priceUsd >= 1000) {
      return '\$${priceUsd.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else if (priceUsd >= 1) {
      return '\$${priceUsd.toStringAsFixed(2)}';
    } else if (priceUsd >= 0.0001) {
      return '\$${priceUsd.toStringAsFixed(4)}';
    } else {
      return '\$${priceUsd.toStringAsFixed(6)}';
    }
  }

  String get formattedVolume {
    if (volume24h >= 1e9) {
      return '\$${(volume24h / 1e9).toStringAsFixed(2)}B';
    } else if (volume24h >= 1e6) {
      return '\$${(volume24h / 1e6).toStringAsFixed(2)}M';
    } else if (volume24h >= 1e3) {
      return '\$${(volume24h / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${volume24h.toStringAsFixed(2)}';
  }

  String get formattedMarketCap {
    if (marketCap >= 1e12) {
      return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e6) {
      return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    }
    return '\$${marketCap.toStringAsFixed(2)}';
  }
}
