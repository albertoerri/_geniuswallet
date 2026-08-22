import '../domain/models/network.dart';
import '../domain/models/token.dart';
import 'onchain_transaction_service.dart';

enum DexRouteType {
  quickswap,
  uniswapV3,
  wpolDirect,
  oneInchAggregator,
}

class DexQuote {
  final DexRouteType routeType;
  final String dexName;
  final double fromAmount;
  final double estimatedToAmount;
  final double rate;
  final double estimatedGasFee;
  final double priceImpactPercentage;
  final String routerAddress;

  const DexQuote({
    required this.routeType,
    required this.dexName,
    required this.fromAmount,
    required this.estimatedToAmount,
    required this.rate,
    required this.estimatedGasFee,
    this.priceImpactPercentage = 0.05,
    required this.routerAddress,
  });
}

abstract class IDexAggregatorService {
  Future<List<DexQuote>> getQuotes({
    required Network network,
    required Token fromToken,
    required Token toToken,
    required double amount,
  });

  Future<DexQuote> getBestQuote({
    required Network network,
    required Token fromToken,
    required Token toToken,
    required double amount,
  });

  Future<OnChainTxResult> executeSwapWithQuote({
    required Network network,
    required String privateKeyHex,
    required Token fromToken,
    required Token toToken,
    required DexQuote quote,
    required double slippage,
  });
}

class DexAggregatorService implements IDexAggregatorService {
  final IOnChainTransactionService _onChainService;

  DexAggregatorService({IOnChainTransactionService? onChainService})
      : _onChainService = onChainService ?? OnChainTransactionService();

  @override
  Future<List<DexQuote>> getQuotes({
    required Network network,
    required Token fromToken,
    required Token toToken,
    required double amount,
  }) async {
    final fromPrice = fromToken.priceUsd > 0 ? fromToken.priceUsd : 0.42;
    final toPrice = toToken.priceUsd > 0 ? toToken.priceUsd : 1.0;
    final baseRate = fromPrice / toPrice;

    final quotes = <DexQuote>[];

    // 1. WPOL Direct Wrap / Unwrap
    if ((fromToken.isNative && toToken.symbol.toUpperCase() == 'WPOL') ||
        (fromToken.symbol.toUpperCase() == 'WPOL' && toToken.isNative)) {
      quotes.add(
        DexQuote(
          routeType: DexRouteType.wpolDirect,
          dexName: 'WPOL Official Contract',
          fromAmount: amount,
          estimatedToAmount: amount * 1.0, // 1:1 wrap
          rate: 1.0,
          estimatedGasFee: 0.001,
          priceImpactPercentage: 0.0,
          routerAddress: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
        ),
      );
      return quotes;
    }

    // 2. QuickSwap V2 Route
    final quickswapRate = baseRate * 0.997; // 0.3% pool fee
    quotes.add(
      DexQuote(
        routeType: DexRouteType.quickswap,
        dexName: 'QuickSwap V2 (Polygon)',
        fromAmount: amount,
        estimatedToAmount: amount * quickswapRate,
        rate: quickswapRate,
        estimatedGasFee: 0.0035,
        priceImpactPercentage: 0.03,
        routerAddress: '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff',
      ),
    );

    // 3. Uniswap V3 Polygon Route
    final uniRate = baseRate * 0.9995; // 0.05% tier
    quotes.add(
      DexQuote(
        routeType: DexRouteType.uniswapV3,
        dexName: 'Uniswap V3 (Polygon)',
        fromAmount: amount,
        estimatedToAmount: amount * uniRate,
        rate: uniRate,
        estimatedGasFee: 0.0042,
        priceImpactPercentage: 0.02,
        routerAddress: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
      ),
    );

    // 4. 1inch Smart Aggregator Route
    final oneInchRate = baseRate * 0.9998;
    quotes.add(
      DexQuote(
        routeType: DexRouteType.oneInchAggregator,
        dexName: '1inch Fusion / Aggregator',
        fromAmount: amount,
        estimatedToAmount: amount * oneInchRate,
        rate: oneInchRate,
        estimatedGasFee: 0.0028,
        priceImpactPercentage: 0.01,
        routerAddress: '0x111111125421cA6dc452d289314280a0f8842A65',
      ),
    );

    // 按预期获得金额从高到低排序，把最优路由排在最前
    quotes.sort((a, b) => b.estimatedToAmount.compareTo(a.estimatedToAmount));
    return quotes;
  }

  @override
  Future<DexQuote> getBestQuote({
    required Network network,
    required Token fromToken,
    required Token toToken,
    required double amount,
  }) async {
    final quotes = await getQuotes(
      network: network,
      fromToken: fromToken,
      toToken: toToken,
      amount: amount,
    );
    return quotes.first;
  }

  @override
  Future<OnChainTxResult> executeSwapWithQuote({
    required Network network,
    required String privateKeyHex,
    required Token fromToken,
    required Token toToken,
    required DexQuote quote,
    required double slippage,
  }) {
    final minToAmount = quote.estimatedToAmount * (1 - (slippage / 100));
    return _onChainService.sendSwapTransaction(
      network: network,
      privateKeyHex: privateKeyHex,
      fromToken: fromToken,
      toToken: toToken,
      fromAmount: quote.fromAmount,
      minToAmount: minToAmount,
    );
  }
}
