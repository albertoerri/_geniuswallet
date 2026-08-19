enum NetworkType {
  evm,
  solana,
  bitcoin,
  tron,
}

class Network {
  final String id;
  final String name;
  final String symbol;
  final int chainId;
  final String rpcUrl;
  final String? blockExplorerUrl;
  final String? iconAsset;
  final NetworkType type;
  final String derivationPath;
  final bool isTestnet;
  final String defaultNamePrefix;

  const Network({
    required this.id,
    required this.name,
    required this.symbol,
    required this.chainId,
    required this.rpcUrl,
    this.blockExplorerUrl,
    this.iconAsset,
    this.type = NetworkType.evm,
    this.derivationPath = "m/44'/60'/0'/0/0",
    this.isTestnet = false,
    required this.defaultNamePrefix,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'chainId': chainId,
      'rpcUrl': rpcUrl,
      'blockExplorerUrl': blockExplorerUrl,
      'iconAsset': iconAsset,
      'type': type.name,
      'derivationPath': derivationPath,
      'isTestnet': isTestnet,
      'defaultNamePrefix': defaultNamePrefix,
    };
  }

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      id: json['id'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      chainId: json['chainId'] as int,
      rpcUrl: json['rpcUrl'] as String,
      blockExplorerUrl: json['blockExplorerUrl'] as String?,
      iconAsset: json['iconAsset'] as String?,
      type: NetworkType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NetworkType.evm,
      ),
      derivationPath: json['derivationPath'] as String? ?? "m/44'/60'/0'/0/0",
      isTestnet: json['isTestnet'] as bool? ?? false,
      defaultNamePrefix: json['defaultNamePrefix'] as String? ?? json['symbol'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Network && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
