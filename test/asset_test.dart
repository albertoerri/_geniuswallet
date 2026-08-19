import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';

void main() {
  group('Token Model Tests', () {
    test('formats balance, price, change, and fiat correctly', () {
      const token = Token(
        id: 'polygon_pol',
        networkId: 'polygon',
        symbol: 'POL',
        name: 'POL',
        decimals: 18,
        priceUsd: 0.4215,
        change24h: 1.84,
        balance: 100.5,
        fiatValue: 42.36075,
        isNative: true,
      );

      expect(token.formattedBalance, '100.5');
      expect(token.formattedPrice, '\$0.4215');
      expect(token.formattedChange, '+1.84%');
      expect(token.formattedFiat, '\$42.36');
      expect(token.isPositiveChange, isTrue);
    });

    test('formats zero and large values correctly', () {
      const zeroToken = Token(
        id: 'zero',
        networkId: 'polygon',
        symbol: 'ZERO',
        name: 'Zero Token',
        balance: 0.0,
        fiatValue: 0.0,
      );
      expect(zeroToken.formattedBalance, '0');
      expect(zeroToken.formattedFiat, '\$0.00');

      const btcToken = Token(
        id: 'btc',
        networkId: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        priceUsd: 61450.0,
        balance: 2.0,
        fiatValue: 122900.0,
      );
      expect(btcToken.formattedPrice, '\$61,450.00');
      expect(btcToken.formattedFiat, '\$122,900.00');
    });
  });

  group('AssetService Tests', () {
    final service = AssetService();

    test('returns correct default tokens for Polygon', () {
      const polygon = Network(
        id: 'polygon',
        name: 'Polygon',
        symbol: 'POL',
        chainId: 137,
        rpcUrl: 'https://polygon-bor-rpc.publicnode.com',
        defaultNamePrefix: 'POL',
      );

      final tokens = service.getDefaultTokensForNetwork(polygon);
      expect(tokens.isNotEmpty, isTrue);
      expect(tokens.any((t) => t.symbol == 'POL' && t.isNative), isTrue);
      expect(tokens.any((t) => t.symbol == 'USDT'), isTrue);
      expect(tokens.any((t) => t.symbol == 'USDC'), isTrue);
    });

    test('returns correct default tokens for BNB Chain', () {
      const bnb = Network(
        id: 'bnb',
        name: 'BNB Chain',
        symbol: 'BNB',
        chainId: 56,
        rpcUrl: 'https://bsc-rpc.publicnode.com',
        defaultNamePrefix: 'BNB',
      );

      final tokens = service.getDefaultTokensForNetwork(bnb);
      expect(tokens.any((t) => t.symbol == 'BNB' && t.isNative), isTrue);
      expect(tokens.any((t) => t.symbol == 'CAKE'), isTrue);
    });
  });

  group('AssetController Tests', () {
    test('loads tokens and computes total balance', () async {
      final repository = AssetRepository();
      final controller = AssetController(repository: repository);

      const polygon = Network(
        id: 'polygon',
        name: 'Polygon',
        symbol: 'POL',
        chainId: 137,
        rpcUrl: 'https://polygon-bor-rpc.publicnode.com',
        defaultNamePrefix: 'POL',
      );

      await controller.loadAssets(
        network: polygon,
        walletAddress: '0x9858EfFD232B4033E47d90003D41EC34EcaEda94',
        walletId: 'w1',
      );

      expect(controller.tokens.isNotEmpty, isTrue);
      expect(controller.isLoading, isFalse);

      // Sub tab switching
      controller.setSubTab(1);
      expect(controller.selectedSubTab, 1);
      controller.setSubTab(2);
      expect(controller.selectedSubTab, 2);
      controller.setSubTab(0);
      expect(controller.selectedSubTab, 0);

      // Testnet Faucet claim
      await controller.claimFaucet(
        network: polygon,
        walletAddress: '0x9858EfFD232B4033E47d90003D41EC34EcaEda94',
        walletId: 'w1',
        tokenSymbol: 'POL',
        amount: 100.0,
      );

      final polToken = controller.tokens.firstWhere((t) => t.symbol == 'POL');
      expect(polToken.balance, 100.0);
      expect(polToken.fiatValue, greaterThan(0));
      expect(controller.totalBalanceUsd, greaterThan(0));
    });
  });
}
