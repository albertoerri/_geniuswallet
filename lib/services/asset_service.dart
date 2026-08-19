import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../domain/models/network.dart';
import '../domain/models/token.dart';

abstract class IAssetService {
  List<Token> getDefaultTokensForNetwork(Network network);
  Future<List<Token>> fetchTokenBalances({
    required Network network,
    required String walletAddress,
    http.Client? client,
  });
}

class AssetService implements IAssetService {
  final http.Client _httpClient;

  AssetService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static final Map<String, List<Token>> _defaultNetworkTokens = {
    'polygon': const [
      Token(
        id: 'polygon_pol',
        networkId: 'polygon',
        symbol: 'POL',
        name: 'POL',
        decimals: 18,
        priceUsd: 0.4215,
        change24h: 1.84,
        isNative: true,
      ),
      Token(
        id: 'polygon_usdt',
        networkId: 'polygon',
        symbol: 'USDT',
        name: 'Tether USD',
        decimals: 6,
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        priceUsd: 1.0001,
        change24h: 0.01,
      ),
      Token(
        id: 'polygon_usdc',
        networkId: 'polygon',
        symbol: 'USDC',
        name: 'USD Coin',
        decimals: 6,
        contractAddress: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359',
        priceUsd: 0.9999,
        change24h: -0.02,
      ),
      Token(
        id: 'polygon_weth',
        networkId: 'polygon',
        symbol: 'WETH',
        name: 'Wrapped Ether',
        decimals: 18,
        contractAddress: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
        priceUsd: 2648.50,
        change24h: 2.15,
      ),
    ],
    'bnb': const [
      Token(
        id: 'bnb_bnb',
        networkId: 'bnb',
        symbol: 'BNB',
        name: 'BNB',
        decimals: 18,
        priceUsd: 586.20,
        change24h: 3.42,
        isNative: true,
      ),
      Token(
        id: 'bnb_usdt',
        networkId: 'bnb',
        symbol: 'USDT',
        name: 'Tether USD (BSC)',
        decimals: 18,
        contractAddress: '0x55d398326f99059fF775485246999027B3197955',
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'bnb_usdc',
        networkId: 'bnb',
        symbol: 'USDC',
        name: 'USD Coin (BSC)',
        decimals: 18,
        contractAddress: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'bnb_cake',
        networkId: 'bnb',
        symbol: 'CAKE',
        name: 'PancakeSwap Token',
        decimals: 18,
        contractAddress: '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82',
        priceUsd: 2.34,
        change24h: -1.12,
      ),
      Token(
        id: 'bnb_eth',
        networkId: 'bnb',
        symbol: 'ETH',
        name: 'Binance-Peg Ethereum',
        decimals: 18,
        contractAddress: '0x2170Ed0880ac9A755fd29B2688956BD959F933F8',
        priceUsd: 2648.50,
        change24h: 2.15,
      ),
    ],
    'ethereum': const [
      Token(
        id: 'eth_eth',
        networkId: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        decimals: 18,
        priceUsd: 2648.50,
        change24h: 2.15,
        isNative: true,
      ),
      Token(
        id: 'eth_usdt',
        networkId: 'ethereum',
        symbol: 'USDT',
        name: 'Tether USD',
        decimals: 6,
        contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'eth_usdc',
        networkId: 'ethereum',
        symbol: 'USDC',
        name: 'USD Coin',
        decimals: 6,
        contractAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'eth_wbtc',
        networkId: 'ethereum',
        symbol: 'WBTC',
        name: 'Wrapped BTC',
        decimals: 8,
        contractAddress: '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599',
        priceUsd: 61450.00,
        change24h: 4.12,
      ),
      Token(
        id: 'eth_dai',
        networkId: 'ethereum',
        symbol: 'DAI',
        name: 'Dai Stablecoin',
        decimals: 18,
        contractAddress: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
        priceUsd: 1.0002,
        change24h: 0.03,
      ),
    ],
    'base': const [
      Token(
        id: 'base_eth',
        networkId: 'base',
        symbol: 'ETH',
        name: 'Ethereum (Base)',
        decimals: 18,
        priceUsd: 2648.50,
        change24h: 2.15,
        isNative: true,
      ),
      Token(
        id: 'base_usdc',
        networkId: 'base',
        symbol: 'USDC',
        name: 'USD Coin (Base)',
        decimals: 6,
        contractAddress: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'base_degen',
        networkId: 'base',
        symbol: 'DEGEN',
        name: 'Degen',
        decimals: 18,
        contractAddress: '0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed',
        priceUsd: 0.0084,
        change24h: 6.28,
      ),
      Token(
        id: 'base_brett',
        networkId: 'base',
        symbol: 'BRETT',
        name: 'Brett',
        decimals: 18,
        contractAddress: '0x532f27101965dd16442E59d40670FaF5eBB142E4',
        priceUsd: 0.0912,
        change24h: -2.45,
      ),
    ],
    'arbitrum': const [
      Token(
        id: 'arb_eth',
        networkId: 'arbitrum',
        symbol: 'ETH',
        name: 'Ethereum (Arbitrum)',
        decimals: 18,
        priceUsd: 2648.50,
        change24h: 2.15,
        isNative: true,
      ),
      Token(
        id: 'arb_arb',
        networkId: 'arbitrum',
        symbol: 'ARB',
        name: 'Arbitrum',
        decimals: 18,
        contractAddress: '0x912CE59144191C1204E64559FE8253a0e49E6548',
        priceUsd: 0.584,
        change24h: 1.15,
      ),
      Token(
        id: 'arb_usdt',
        networkId: 'arbitrum',
        symbol: 'USDT',
        name: 'Tether USD (Arb)',
        decimals: 6,
        contractAddress: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'arb_usdc',
        networkId: 'arbitrum',
        symbol: 'USDC',
        name: 'USD Coin (Arb)',
        decimals: 6,
        contractAddress: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
    ],
    'solana': const [
      Token(
        id: 'sol_sol',
        networkId: 'solana',
        symbol: 'SOL',
        name: 'Solana',
        decimals: 9,
        priceUsd: 144.80,
        change24h: 4.82,
        isNative: true,
      ),
      Token(
        id: 'sol_usdc',
        networkId: 'solana',
        symbol: 'USDC',
        name: 'USD Coin (SPL)',
        decimals: 6,
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'sol_usdt',
        networkId: 'solana',
        symbol: 'USDT',
        name: 'Tether USD (SPL)',
        decimals: 6,
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'sol_bonk',
        networkId: 'solana',
        symbol: 'BONK',
        name: 'Bonk',
        decimals: 5,
        priceUsd: 0.0000214,
        change24h: 8.91,
      ),
    ],
    'bitcoin': const [
      Token(
        id: 'btc_btc',
        networkId: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        decimals: 8,
        priceUsd: 61450.00,
        change24h: 3.12,
        isNative: true,
      ),
    ],
    'tron': const [
      Token(
        id: 'tron_trx',
        networkId: 'tron',
        symbol: 'TRX',
        name: 'TRON',
        decimals: 6,
        priceUsd: 0.1345,
        change24h: 1.05,
        isNative: true,
      ),
      Token(
        id: 'tron_usdt',
        networkId: 'tron',
        symbol: 'USDT',
        name: 'Tether USD (TRC20)',
        decimals: 6,
        priceUsd: 1.0000,
        change24h: 0.00,
      ),
      Token(
        id: 'tron_usdd',
        networkId: 'tron',
        symbol: 'USDD',
        name: 'Decentralized USD',
        decimals: 18,
        priceUsd: 0.9995,
        change24h: -0.05,
      ),
    ],
  };

  @override
  List<Token> getDefaultTokensForNetwork(Network network) {
    final list = _defaultNetworkTokens[network.id.toLowerCase()];
    if (list != null && list.isNotEmpty) {
      return list;
    }
    // Fallback default token for unknown network
    return [
      Token(
        id: '${network.id}_native',
        networkId: network.id,
        symbol: network.symbol,
        name: network.name,
        decimals: 18,
        priceUsd: 1.0,
        change24h: 0.0,
        isNative: true,
      ),
    ];
  }

  @override
  Future<List<Token>> fetchTokenBalances({
    required Network network,
    required String walletAddress,
    http.Client? client,
  }) async {
    final defaultTokens = getDefaultTokensForNetwork(network);
    final activeClient = client ?? _httpClient;

    // Fetch live market prices in parallel if possible
    final livePrices = await _fetchLivePrices(activeClient);

    // Get list of RPC endpoints with fallback
    final rpcCandidates = <String>[];
    if (network.rpcUrl.isNotEmpty) {
      rpcCandidates.add(network.rpcUrl);
    }
    final configuredFallbacks = AppConfig.rpcFallbackMap[network.id.toLowerCase()];
    if (configuredFallbacks != null) {
      for (final fb in configuredFallbacks) {
        if (!rpcCandidates.contains(fb)) {
          rpcCandidates.add(fb);
        }
      }
    }

    final updatedTokens = <Token>[];

    for (final token in defaultTokens) {
      try {
        double balance = 0.0;
        
        // Update price with live price feed if available
        double price = token.priceUsd;
        double change = token.change24h;
        if (livePrices.containsKey(token.symbol.toUpperCase())) {
          final liveData = livePrices[token.symbol.toUpperCase()]!;
          price = liveData['price'] ?? price;
          change = liveData['change24h'] ?? change;
        }

        if (network.type == NetworkType.evm && rpcCandidates.isNotEmpty) {
          if (token.isNative) {
            balance = await _fetchNativeBalanceWithFallback(
              rpcUrls: rpcCandidates,
              address: walletAddress,
              decimals: token.decimals,
              client: activeClient,
            );
          } else if (token.contractAddress != null) {
            balance = await _fetchErc20BalanceWithFallback(
              rpcUrls: rpcCandidates,
              contractAddress: token.contractAddress!,
              walletAddress: walletAddress,
              decimals: token.decimals,
              client: activeClient,
            );
          }
        } else if (network.type == NetworkType.bitcoin && token.isNative) {
          balance = await _fetchBitcoinBalance(
            address: walletAddress,
            client: activeClient,
          );
        } else if (network.type == NetworkType.solana && token.isNative) {
          balance = await _fetchSolanaBalance(
            rpcUrls: rpcCandidates,
            address: walletAddress,
            client: activeClient,
          );
        }

        final fiat = balance * price;
        updatedTokens.add(
          token.copyWith(
            balance: balance,
            fiatValue: fiat,
            priceUsd: price,
            change24h: change,
          ),
        );
      } catch (e) {
        debugPrint('Error fetching balance for token ${token.symbol} on ${network.name}: $e');
        updatedTokens.add(token.copyWith(
          fiatValue: token.balance * token.priceUsd,
        ));
      }
    }

    return updatedTokens;
  }

  /// Fetches live cryptocurrency market prices with fallback
  Future<Map<String, Map<String, double>>> _fetchLivePrices(http.Client client) async {
    final result = <String, Map<String, double>>{};
    try {
      final uri = Uri.parse(
        '${AppConfig.coinGeckoSimplePriceUrl}?ids=matic-network,ethereum,binancecoin,solana,bitcoin,tether,usd-coin,tron,dai,arbitrum&vs_currencies=usd&include_24hr_change=true',
      );
      final response = await client.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        void mapPrice(String geckoId, String symbol) {
          if (data.containsKey(geckoId)) {
            final coinData = data[geckoId] as Map<String, dynamic>;
            final price = (coinData['usd'] as num?)?.toDouble() ?? 0.0;
            final change = (coinData['usd_24h_change'] as num?)?.toDouble() ?? 0.0;
            result[symbol] = {'price': price, 'change24h': change};
          }
        }

        mapPrice('matic-network', 'POL');
        mapPrice('matic-network', 'MATIC');
        mapPrice('ethereum', 'ETH');
        mapPrice('ethereum', 'WETH');
        mapPrice('binancecoin', 'BNB');
        mapPrice('solana', 'SOL');
        mapPrice('bitcoin', 'BTC');
        mapPrice('bitcoin', 'WBTC');
        mapPrice('tether', 'USDT');
        mapPrice('usd-coin', 'USDC');
        mapPrice('tron', 'TRX');
        mapPrice('dai', 'DAI');
        mapPrice('arbitrum', 'ARB');
      }
    } catch (_) {
      // Gracefully silent fallback to default prices
    }
    return result;
  }

  Future<double> _fetchNativeBalanceWithFallback({
    required List<String> rpcUrls,
    required String address,
    required int decimals,
    required http.Client client,
  }) async {
    for (final rpc in rpcUrls) {
      try {
        final balance = await _fetchNativeBalance(
          rpcUrl: rpc,
          address: address,
          decimals: decimals,
          client: client,
        );
        return balance;
      } catch (_) {
        continue;
      }
    }
    return 0.0;
  }

  Future<double> _fetchErc20BalanceWithFallback({
    required List<String> rpcUrls,
    required String contractAddress,
    required String walletAddress,
    required int decimals,
    required http.Client client,
  }) async {
    for (final rpc in rpcUrls) {
      try {
        final balance = await _fetchErc20Balance(
          rpcUrl: rpc,
          contractAddress: contractAddress,
          walletAddress: walletAddress,
          decimals: decimals,
          client: client,
        );
        return balance;
      } catch (_) {
        continue;
      }
    }
    return 0.0;
  }

  Future<double> _fetchNativeBalance({
    required String rpcUrl,
    required String address,
    required int decimals,
    required http.Client client,
  }) async {
    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'eth_getBalance',
      'params': [address, 'latest'],
      'id': 1,
    });

    final response = await client
        .post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final resultHex = data['result'] as String?;
      if (resultHex != null && resultHex.startsWith('0x')) {
        final hex = resultHex.substring(2);
        final wei = BigInt.parse(hex.isEmpty ? '0' : hex, radix: 16);
        return _formatBigIntBalance(wei, decimals);
      }
    }
    return 0.0;
  }

  Future<double> _fetchErc20Balance({
    required String rpcUrl,
    required String contractAddress,
    required String walletAddress,
    required int decimals,
    required http.Client client,
  }) async {
    final cleanAddress = walletAddress.startsWith('0x') ? walletAddress.substring(2) : walletAddress;
    final paddedAddress = cleanAddress.padLeft(64, '0');
    final data = '0x70a08231$paddedAddress';

    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'eth_call',
      'params': [
        {'to': contractAddress, 'data': data},
        'latest'
      ],
      'id': 1,
    });

    final response = await client
        .post(
          Uri.parse(rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: payload,
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final resultHex = json['result'] as String?;
      if (resultHex != null && resultHex.startsWith('0x')) {
        final hexStr = resultHex.substring(2);
        if (hexStr.isNotEmpty) {
          final rawAmount = BigInt.parse(hexStr, radix: 16);
          return _formatBigIntBalance(rawAmount, decimals);
        }
      }
    }
    return 0.0;
  }

  Future<double> _fetchBitcoinBalance({
    required String address,
    required http.Client client,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.btcScanUrl}/address/$address');
      final response = await client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final chainStats = data['chain_stats'] as Map<String, dynamic>?;
        if (chainStats != null) {
          final funded = (chainStats['funded_txo_sum'] as num?)?.toInt() ?? 0;
          final spent = (chainStats['spent_txo_sum'] as num?)?.toInt() ?? 0;
          final satoshis = funded - spent;
          if (satoshis > 0) {
            return satoshis / 100000000.0; // 8 decimals for BTC
          }
        }
      }
    } catch (_) {}
    return 0.0;
  }

  Future<double> _fetchSolanaBalance({
    required List<String> rpcUrls,
    required String address,
    required http.Client client,
  }) async {
    for (final rpc in rpcUrls) {
      try {
        final payload = jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getBalance',
          'params': [address]
        });
        final response = await client
            .post(
              Uri.parse(rpc),
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final result = data['result'] as Map<String, dynamic>?;
          final lamports = (result?['value'] as num?)?.toDouble() ?? 0.0;
          if (lamports > 0) {
            return lamports / 1000000000.0; // 9 decimals for SOL
          }
          return 0.0;
        }
      } catch (_) {
        continue;
      }
    }
    return 0.0;
  }

  double _formatBigIntBalance(BigInt amount, int decimals) {
    if (amount == BigInt.zero) return 0.0;
    final divisor = math.pow(10, decimals).toDouble();
    return amount.toDouble() / divisor;
  }
}
