/// Centralized Configuration for GeniusWallet
/// Edit this file anytime to update RPC keys, endpoints, or API services.
class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------------------
  // Alchemy RPC Configuration (from greatlovedao)
  // ---------------------------------------------------------------------------
  static const String alchemyApiKey = 'sdMZ_uQfOljspcoDboCNd';

  static const String alchemyDomainPolygon = 'https://polygon-mainnet.g.alchemy.com/v2/';
  static const String alchemyDomainEth = 'https://eth-mainnet.g.alchemy.com/v2/';
  static const String alchemyDomainBase = 'https://base-mainnet.g.alchemy.com/v2/';
  static const String alchemyDomainBnb = 'https://bnb-mainnet.g.alchemy.com/v2/';
  static const String alchemyDomainSolana = 'https://solana-mainnet.g.alchemy.com/v2/';

  static String get alchemyPolygonRpc => '$alchemyDomainPolygon$alchemyApiKey';
  static String get alchemyEthRpc => '$alchemyDomainEth$alchemyApiKey';
  static String get alchemyBaseRpc => '$alchemyDomainBase$alchemyApiKey';
  static String get alchemyBnbRpc => '$alchemyDomainBnb$alchemyApiKey';
  static String get alchemySolanaRpc => '$alchemyDomainSolana$alchemyApiKey';

  // ---------------------------------------------------------------------------
  // Fallback Public RPC Endpoints (automatic failover if primary hits rate limit)
  // ---------------------------------------------------------------------------
  static const Map<String, List<String>> rpcFallbackMap = {
    'polygon': [
      'https://polygon-mainnet.g.alchemy.com/v2/sdMZ_uQfOljspcoDboCNd',
      'https://polygon-bor-rpc.publicnode.com',
      'https://1rpc.io/matic',
      'https://rpc.ankr.com/polygon',
      'https://polygon.llamarpc.com',
    ],
    'bnb': [
      'https://bsc-rpc.publicnode.com',
      'https://1rpc.io/bnb',
      'https://rpc.ankr.com/bsc',
      'https://binance.llamarpc.com',
      'https://bsc-dataseed.binance.org',
    ],
    'ethereum': [
      'https://eth-mainnet.g.alchemy.com/v2/sdMZ_uQfOljspcoDboCNd',
      'https://ethereum-rpc.publicnode.com',
      'https://1rpc.io/eth',
      'https://rpc.ankr.com/eth',
      'https://eth.llamarpc.com',
    ],
    'base': [
      'https://base-mainnet.g.alchemy.com/v2/sdMZ_uQfOljspcoDboCNd',
      'https://base-rpc.publicnode.com',
      'https://mainnet.base.org',
      'https://1rpc.io/base',
    ],
    'arbitrum': [
      'https://arbitrum-one-rpc.publicnode.com',
      'https://arb1.arbitrum.io/rpc',
      'https://1rpc.io/arb',
    ],
    'solana': [
      'https://api.mainnet-beta.solana.com',
      'https://solana-rpc.publicnode.com',
    ],
    'tron': [
      'https://api.trongrid.io',
      'https://tron-rpc.publicnode.com',
    ],
    'bitcoin': [
      'https://blockstream.info/api',
      'https://blockchain.info',
    ],
  };

  // ---------------------------------------------------------------------------
  // Market Price Feed APIs
  // ---------------------------------------------------------------------------
  static const String coinGeckoSimplePriceUrl =
      'https://api.coingecko.com/api/v3/simple/price';

  static const String binanceTickerPriceUrl =
      'https://api.binance.com/api/v3/ticker/price';

  // ---------------------------------------------------------------------------
  // Block Explorers
  // ---------------------------------------------------------------------------
  static const String polygonScanUrl = 'https://polygonscan.com';
  static const String bscScanUrl = 'https://bscscan.com';
  static const String etherScanUrl = 'https://etherscan.io';
  static const String baseScanUrl = 'https://basescan.org';
  static const String arbiScanUrl = 'https://arbiscan.io';
  static const String solScanUrl = 'https://solscan.io';
  static const String tronScanUrl = 'https://tronscan.org';
  static const String btcScanUrl = 'https://blockstream.info';
}
