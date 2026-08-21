import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geniuswallet/core/theme/app_theme.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/market_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/presentation/screens/main_navigation_screen.dart';
import 'package:geniuswallet/repositories/network_repository.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';
import 'package:geniuswallet/services/crypto_key_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/services/wallet_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'package:geniuswallet/storage/secure_storage_service.dart';

import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';

void main() {
  testWidgets('App renders WelcomeScreen on initial launch when no wallets exist', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(sharedPrefs);
    final secureStorage = SecureStorageService();
    final cryptoService = CryptoKeyService();
    final networkService = NetworkService();
    final walletService = WalletService(cryptoService: cryptoService);
    final assetService = AssetService();

    final networkRepo = NetworkRepository(
      networkService: networkService,
      localStorageService: localStorage,
    );
    final walletRepo = WalletRepository(
      localStorageService: localStorage,
      secureStorageService: secureStorage,
    );
    final assetRepo = AssetRepository(assetService: assetService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageController(localStorage)),
          ChangeNotifierProvider(create: (_) => NetworkController(networkRepo)),
          ChangeNotifierProvider(
            create: (_) => WalletController(
              repository: walletRepo,
              walletService: walletService,
            ),
          ),
          ChangeNotifierProvider(create: (_) => AssetController(repository: assetRepo)),
          ChangeNotifierProvider(create: (_) => MarketController(localStorage)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Welcome screen text & actions matching TokenPocket
    expect(find.text('Your Multi-chain Wallet, Safe & Easy'), findsOneWidget);
    expect(find.text('I have an account'), findsOneWidget);
    expect(find.text('No accounts'), findsOneWidget);

    // Verify 5 bottom navigation tabs
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
  });
}
