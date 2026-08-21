import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geniuswallet/domain/models/market_item.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/market_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/presentation/screens/market/market_screen.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/repositories/network_repository.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';
import 'package:geniuswallet/services/crypto_key_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/services/wallet_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'package:geniuswallet/storage/secure_storage_service.dart';

Widget createTestMarketApp(Widget child, {required LocalStorageService storage}) {
  final crypto = CryptoKeyService();
  final netService = NetworkService();
  final walletService = WalletService(cryptoService: crypto);
  final assetService = AssetService();

  final netRepo = NetworkRepository(networkService: netService, localStorageService: storage);
  final walletRepo = WalletRepository(localStorageService: storage, secureStorageService: SecureStorageService());
  final assetRepo = AssetRepository(assetService: assetService);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageController(storage)),
      ChangeNotifierProvider(create: (_) => NetworkController(netRepo)),
      ChangeNotifierProvider(create: (_) => WalletController(repository: walletRepo, walletService: walletService)),
      ChangeNotifierProvider(create: (_) => AssetController(repository: assetRepo)),
      ChangeNotifierProvider(create: (_) => MarketController(storage)),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarketController Tests', () {
    test('Initializes with default market items and metrics', () {
      final controller = MarketController();

      expect(controller.displayedItems.isNotEmpty, true);
      expect(controller.totalMarketCap > 0, true);
      expect(controller.currentTab, MarketTab.hot);
    });

    test('Filtering by tab: Gainers and Losers', () {
      final controller = MarketController();

      controller.setTab(MarketTab.gainers);
      for (final item in controller.displayedItems) {
        expect(item.change24h > 0, true);
      }

      controller.setTab(MarketTab.losers);
      for (final item in controller.displayedItems) {
        expect(item.change24h < 0, true);
      }
    });

    test('Watchlist favorites toggle', () {
      final controller = MarketController();

      expect(controller.isFavorite('btc'), true);
      controller.toggleFavorite('btc');
      expect(controller.isFavorite('btc'), false);
      controller.toggleFavorite('btc');
      expect(controller.isFavorite('btc'), true);
    });

    test('Sorting by price and volume', () {
      final controller = MarketController();

      controller.toggleSort(MarketSortField.price);
      expect(controller.sortField, MarketSortField.price);
      expect(controller.sortOrder, MarketSortOrder.descending);

      final itemsDesc = controller.displayedItems;
      expect(itemsDesc.first.priceUsd >= itemsDesc.last.priceUsd, true);

      controller.toggleSort(MarketSortField.price);
      expect(controller.sortOrder, MarketSortOrder.ascending);

      final itemsAsc = controller.displayedItems;
      expect(itemsAsc.first.priceUsd <= itemsAsc.last.priceUsd, true);
    });

    test('Search query filtering', () {
      final controller = MarketController();

      controller.setSearchQuery('Polygon');
      expect(controller.displayedItems.every((item) => item.name.contains('Polygon') || item.symbol.contains('POL')), true);
    });
  });

  group('MarketScreen UI Tests', () {
    testWidgets('Renders MarketScreen tabs, stats, and crypto rows', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      await tester.pumpWidget(createTestMarketApp(const MarketScreen(), storage: storage));
      await tester.pumpAndSettle();

      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Hot'), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Gainers'), findsOneWidget);
      expect(find.text('Losers'), findsOneWidget);

      // Verify top market cap tokens rendered in Hot tab
      expect(find.text('BTC'), findsAtLeastNWidgets(1));
      expect(find.text('ETH'), findsAtLeastNWidgets(1));
      expect(find.text('USDT'), findsAtLeastNWidgets(1));
      expect(find.text('BNB'), findsAtLeastNWidgets(1));
      expect(find.text('SOL'), findsAtLeastNWidgets(1));

      // Tap BTC to open Token Detail Sheet
      await tester.tap(find.text('BTC').first);
      await tester.pumpAndSettle();

      expect(find.text('Market Statistics'), findsOneWidget);
      expect(find.text('Trade / Swap'), findsOneWidget);

      // Verify Timeframe selector chips rendered (1H, 24H, 7D, 1M, 1Y, ALL)
      expect(find.text('1H'), findsOneWidget);
      expect(find.text('24H'), findsOneWidget);
      expect(find.text('7D'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);

      // Tap 7D timeframe
      await tester.tap(find.text('7D'));
      await tester.pumpAndSettle();
    });

    testWidgets('MarketScreen switches to Gainers and Watchlist tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      await tester.pumpWidget(createTestMarketApp(const MarketScreen(), storage: storage));
      await tester.pumpAndSettle();

      // Switch to Gainers tab
      await tester.tap(find.text('Gainers'));
      await tester.pumpAndSettle();

      expect(find.text('PEPE'), findsAtLeastNWidgets(1));

      // Switch to Watchlist tab
      await tester.tap(find.text('Watchlist'));
      await tester.pumpAndSettle();

      expect(find.text('BTC'), findsAtLeastNWidgets(1));
    });
  });
}
