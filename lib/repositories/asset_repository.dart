import '../domain/models/network.dart';
import '../domain/models/token.dart';
import '../services/asset_service.dart';

abstract class IAssetRepository {
  Future<List<Token>> getTokensForWallet({
    required Network network,
    required String walletAddress,
    bool forceRefresh = false,
  });

  Future<double> getTotalBalanceUsd({
    required Network network,
    required String walletAddress,
  });

  Future<void> updateTokenBalance({
    required Network network,
    required String walletAddress,
    required String tokenSymbol,
    required double newBalance,
  });

  Future<void> claimFaucetTokens({
    required Network network,
    required String walletAddress,
    required String tokenSymbol,
    required double amount,
  });
}

class AssetRepository implements IAssetRepository {
  final IAssetService _assetService;
  final Map<String, List<Token>> _memoryCache = {};
  final Map<String, Map<String, double>> _customBalances = {};

  AssetRepository({IAssetService? assetService})
      : _assetService = assetService ?? AssetService();

  String _cacheKey(String networkId, String address) =>
      '${networkId.toLowerCase()}_${address.toLowerCase()}';

  @override
  Future<List<Token>> getTokensForWallet({
    required Network network,
    required String walletAddress,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(network.id, walletAddress);

    if (!forceRefresh && _memoryCache.containsKey(key)) {
      return _applyCustomBalances(network, walletAddress, _memoryCache[key]!);
    }

    try {
      final tokens = await _assetService.fetchTokenBalances(
        network: network,
        walletAddress: walletAddress,
      );
      final finalTokens = _applyCustomBalances(network, walletAddress, tokens);
      _memoryCache[key] = finalTokens;
      return finalTokens;
    } catch (_) {
      if (_memoryCache.containsKey(key)) {
        return _applyCustomBalances(network, walletAddress, _memoryCache[key]!);
      }
      final fallback = _assetService.getDefaultTokensForNetwork(network);
      final finalTokens = _applyCustomBalances(network, walletAddress, fallback);
      _memoryCache[key] = finalTokens;
      return finalTokens;
    }
  }

  List<Token> _applyCustomBalances(Network network, String walletAddress, List<Token> tokens) {
    final key = _cacheKey(network.id, walletAddress);
    final customs = _customBalances[key];
    if (customs == null || customs.isEmpty) return tokens;

    return tokens.map((token) {
      if (customs.containsKey(token.symbol.toUpperCase())) {
        final customBal = customs[token.symbol.toUpperCase()]!;
        final fiat = customBal * token.priceUsd;
        return token.copyWith(
          balance: customBal,
          fiatValue: fiat,
        );
      }
      return token;
    }).toList();
  }

  @override
  Future<void> updateTokenBalance({
    required Network network,
    required String walletAddress,
    required String tokenSymbol,
    required double newBalance,
  }) async {
    final key = _cacheKey(network.id, walletAddress);
    _customBalances.putIfAbsent(key, () => {})[tokenSymbol.toUpperCase()] = newBalance;

    if (_memoryCache.containsKey(key)) {
      _memoryCache[key] = _applyCustomBalances(network, walletAddress, _memoryCache[key]!);
    }
  }

  @override
  Future<void> claimFaucetTokens({
    required Network network,
    required String walletAddress,
    required String tokenSymbol,
    required double amount,
  }) async {
    final key = _cacheKey(network.id, walletAddress);
    final currentCustoms = _customBalances.putIfAbsent(key, () => {});
    final currentBal = currentCustoms[tokenSymbol.toUpperCase()] ?? 0.0;
    currentCustoms[tokenSymbol.toUpperCase()] = currentBal + amount;

    if (_memoryCache.containsKey(key)) {
      _memoryCache[key] = _applyCustomBalances(network, walletAddress, _memoryCache[key]!);
    }
  }

  @override
  Future<double> getTotalBalanceUsd({
    required Network network,
    required String walletAddress,
  }) async {
    final tokens = await getTokensForWallet(
      network: network,
      walletAddress: walletAddress,
    );
    double total = 0.0;
    for (final token in tokens) {
      total += token.fiatValue;
    }
    return total;
  }
}
