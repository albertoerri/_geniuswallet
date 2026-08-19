import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geniuswallet/core/theme/app_theme.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/presentation/screens/main_navigation_screen.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/repositories/network_repository.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';
import 'package:geniuswallet/services/crypto_key_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/services/wallet_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'wallet_repository_test.dart';

void main() {
  testWidgets('Complete user flow: Welcome -> Master Password -> Select Network -> Import Wallets -> Private Key -> Dashboard', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(sharedPrefs);
    final secureStorage = MockSecureStorageService();
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

    final networkController = NetworkController(networkRepo);
    final walletController = WalletController(
      repository: walletRepo,
      walletService: walletService,
    );
    final assetController = AssetController(repository: assetRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: networkController),
          ChangeNotifierProvider.value(value: walletController),
          ChangeNotifierProvider.value(value: assetController),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State: Welcome Screen
    expect(find.text('Your Multi-chain Wallet, Safe & Easy'), findsOneWidget);

    // 2. Tap "I have an account"
    await tester.tap(find.text('I have an account'));
    await tester.pumpAndSettle();

    // 3. Set Master Password Screen
    expect(find.text('Set Master Password'), findsOneWidget);
    final pwFields = find.byType(TextField);
    await tester.enterText(pwFields.at(0), 'password123');
    await tester.enterText(pwFields.at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Read & agree with '));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // 4. Select Network Screen
    expect(find.text('Select A Network'), findsOneWidget);
    expect(find.text('SingleNetwork'), findsOneWidget);
    expect(find.text('Polygon'), findsOneWidget);
    expect(find.text('BNB Chain'), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('Base'), findsOneWidget);

    // 5. Select Polygon -> Opens Import Wallets options menu
    await tester.tap(find.text('Polygon'));
    await tester.pumpAndSettle();

    expect(find.text('Import Wallets'), findsOneWidget);
    expect(find.text('Recovery Phrase'), findsOneWidget);
    expect(find.text('Private Key'), findsOneWidget);
    expect(find.text('Keystore'), findsOneWidget);
    expect(find.text('Sync Wallet'), findsOneWidget);

    // 6. Select Private Key -> Opens 1:1 Import Wallet Screen
    await tester.tap(find.text('Private Key'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Import Wallet'), findsOneWidget);
    expect(find.text('Phrase'), findsOneWidget);
    expect(find.text('Private Key'), findsOneWidget);
    expect(find.text('Keystore'), findsOneWidget);

    // Enter valid 64-hex EVM Private Key
    const testPrivKey = '4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f36088a';
    final textFields = find.byType(TextField);
    // First TextField is secret, second is wallet name
    await tester.enterText(textFields.first, testPrivKey);
    await tester.pumpAndSettle();

    // Check Terms / Service Agreement
    await tester.tap(find.text('Read & agree with '));
    await tester.pumpAndSettle();

    // Tap Import Wallet button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Import Wallet'));
    await tester.pumpAndSettle();

    // 7. Should navigate to Wallet Dashboard with active wallet!
    expect(find.text('POL-1'), findsOneWidget);
    expect(find.text('Click to switch node'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);
    expect(find.text('Swap'), findsOneWidget);
    expect(find.text('More Tools'), findsOneWidget);
  });

  testWidgets('Complete user flow: Import with Recovery Phrase', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(sharedPrefs);
    final secureStorage = MockSecureStorageService();
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

    final networkController = NetworkController(networkRepo);
    final walletController = WalletController(
      repository: walletRepo,
      walletService: walletService,
    );
    final assetController = AssetController(repository: assetRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: networkController),
          ChangeNotifierProvider.value(value: walletController),
          ChangeNotifierProvider.value(value: assetController),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "I have an account"
    await tester.tap(find.text('I have an account'));
    await tester.pumpAndSettle();

    // Set Master Password
    final pwFields = find.byType(TextField);
    await tester.enterText(pwFields.at(0), 'password123');
    await tester.enterText(pwFields.at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Read & agree with '));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Tap Polygon -> Import Wallets
    await tester.tap(find.text('Polygon'));
    await tester.pumpAndSettle();

    // Tap Recovery Phrase
    await tester.tap(find.text('Recovery Phrase'));
    await tester.pumpAndSettle();

    // Enter valid 12-word mnemonic
    const testMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, testMnemonic);
    await tester.pumpAndSettle();

    // Agree and Import
    await tester.tap(find.text('Read & agree with '));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Import Wallet'));
    await tester.pumpAndSettle();

    // Dashboard check
    expect(find.text('POL-1'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('Complete 1:1 Creation flow: Welcome -> Master Password -> Network -> Config -> Backup Tips -> Phrase -> Verify -> Dashboard', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(sharedPrefs);
    final secureStorage = MockSecureStorageService();
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

    final networkController = NetworkController(networkRepo);
    final walletController = WalletController(
      repository: walletRepo,
      walletService: walletService,
    );
    final assetController = AssetController(repository: assetRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: networkController),
          ChangeNotifierProvider.value(value: walletController),
          ChangeNotifierProvider.value(value: assetController),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State: Welcome Screen -> Tap "No accounts"
    expect(find.text('No accounts'), findsOneWidget);
    await tester.tap(find.text('No accounts'));
    await tester.pumpAndSettle();

    // 2. Set Master Password Screen
    expect(find.text('Set Master Password'), findsOneWidget);
    final pwFields = find.byType(TextField);
    await tester.enterText(pwFields.at(0), 'password123');
    await tester.enterText(pwFields.at(1), 'password123');
    await tester.pumpAndSettle();

    // Agree to terms
    await tester.tap(find.text('Read & agree with '));
    await tester.pumpAndSettle();

    // Confirm Master Password
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // 3. Select Network Screen -> Tap Polygon
    expect(find.text('Select A Network'), findsOneWidget);
    await tester.tap(find.text('Polygon'));
    await tester.pumpAndSettle();

    // 4. Create Wallet Config Screen
    expect(find.text('Create Polygon'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next Step'));
    await tester.pumpAndSettle();

    // 5. Backup Tips Screen
    expect(find.text('Backup Phrase,keep wallet safe'), findsOneWidget);
    expect(find.text('Generate Mnemonic'), findsOneWidget);
    await tester.tap(find.text('Generate Mnemonic'));
    await tester.pumpAndSettle();

    // 6. Backup Phrase Screen (Display mnemonic)
    expect(find.text('Backup Recovery Phrase'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    // 7. Assert Navigation to Dashboard
    expect(find.text('POL-1'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('Drawer & SelectNetwork Add Wallet flow: opens AddWalletBottomSheet with Create/Import/Cancel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(sharedPrefs);
    final secureStorage = MockSecureStorageService();
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

    // Save an existing wallet
    await walletRepo.saveWallet(
      wallet: Wallet(
        id: 'w-pol-1',
        name: 'POL-1',
        address: '0x9858EfFD232B4033E47d90003D41EC34EcaEda94',
        networkId: 'polygon',
        importType: WalletImportType.generated,
        createdAt: DateTime.now(),
        isBackedUp: true,
      ),
      secret: '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );

    final networkController = NetworkController(networkRepo);
    await networkController.loadNetworks();
    final walletController = WalletController(
      repository: walletRepo,
      walletService: walletService,
    );
    await walletController.loadWallets();
    final assetController = AssetController(repository: assetRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: networkController),
          ChangeNotifierProvider.value(value: walletController),
          ChangeNotifierProvider.value(value: assetController),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify on Dashboard
    expect(find.text('POL-1'), findsOneWidget);

    // 2. Open Drawer
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Wallet List'), findsOneWidget);

    // 3. Tap + circle icon next to chain name
    await tester.tap(find.byKey(const Key('drawer_add_wallet_button')));
    await tester.pumpAndSettle();

    // 4. Verify AddWalletBottomSheet is shown
    expect(find.text('Create Wallet'), findsOneWidget);
    expect(find.text('Import Wallet'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // 5. Tap Cancel to dismiss
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Create Wallet'), findsNothing);

    // 6. Tap top-bar wallet icon to open SelectNetwork in neutral mode
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Select A Network'), findsOneWidget);

    // 7. Tap BNB Chain -> Opens AddWalletBottomSheet for BNB Chain
    await tester.tap(find.text('BNB Chain'));
    await tester.pumpAndSettle();

    expect(find.text('Create Wallet'), findsOneWidget);
    expect(find.text('Import Wallet'), findsOneWidget);

    // 8. Tap Import Wallet -> Navigates to ImportWalletsOptionsScreen
    await tester.tap(find.text('Import Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Import Wallets'), findsOneWidget);
    expect(find.text('Recovery Phrase'), findsOneWidget);
    expect(find.text('Private Key'), findsOneWidget);
  });
}
