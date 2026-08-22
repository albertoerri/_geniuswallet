import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/environment_controller.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/market_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/services/crypto_key_service.dart';
import 'package:geniuswallet/services/environment_service.dart';
import 'package:geniuswallet/services/onchain_transaction_service.dart';
import 'package:geniuswallet/presentation/screens/assets/wallet_dashboard_screen.dart';
import 'package:geniuswallet/presentation/screens/scan/scan_qr_screen.dart';
import 'package:geniuswallet/presentation/screens/search/search_hub_screen.dart';
import 'package:geniuswallet/presentation/screens/swap/swap_screen.dart';
import 'package:geniuswallet/presentation/screens/tools/more_tools_screen.dart';
import 'package:geniuswallet/presentation/screens/transfer/receive_screen.dart';
import 'package:geniuswallet/presentation/screens/transfer/send_screen.dart';
import 'package:geniuswallet/presentation/screens/wallet/wallet_details_screen.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/repositories/network_repository.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';

class MockWalletRepository implements IWalletRepository {
  List<Wallet> wallets = [];
  String? activeId;
  final Map<String, String> secrets = {};

  @override
  Future<List<Wallet>> getWallets() async => List.from(wallets);

  @override
  Future<Wallet?> getActiveWallet() async {
    if (wallets.isEmpty) return null;
    if (activeId != null) {
      try {
        return wallets.firstWhere((w) => w.id == activeId);
      } catch (_) {}
    }
    return wallets.first;
  }

  @override
  Future<void> setActiveWallet(String walletId) async {
    activeId = walletId;
  }

  @override
  Future<void> saveWallet({required Wallet wallet, required String secret}) async {
    wallets.add(wallet);
    secrets[wallet.id] = secret;
    activeId = wallet.id;
  }

  @override
  Future<String?> getWalletSecret(String walletId) async {
    return secrets[walletId] ?? 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  }

  @override
  Future<void> renameWallet(String walletId, String newName) async {
    final idx = wallets.indexWhere((w) => w.id == walletId);
    if (idx >= 0) {
      wallets[idx] = wallets[idx].copyWith(name: newName);
    }
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    wallets.removeWhere((w) => w.id == walletId);
    secrets.remove(walletId);
    if (activeId == walletId) {
      activeId = wallets.isNotEmpty ? wallets.first.id : null;
    }
  }

  @override
  Future<int> getWalletCountForNetwork(String networkId) async {
    return wallets.where((w) => w.networkId.toLowerCase() == networkId.toLowerCase()).length;
  }
}

void main() {
  late MockWalletRepository mockWalletRepo;
  late NetworkController networkController;
  late WalletController walletController;
  late AssetController assetController;
  late LanguageController languageController;
  late Wallet sampleWallet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(sharedPrefs);
    final networkService = NetworkService();
    final networkRepo = NetworkRepository(
      networkService: networkService,
      localStorageService: localStorage,
    );

    mockWalletRepo = MockWalletRepository();
    sampleWallet = Wallet(
      id: 'wallet-1',
      name: 'POL-1',
      address: '0x9858622f9D19E507a2752945D78385472147da94',
      networkId: 'polygon',
      importType: WalletImportType.recoveryPhrase,
      createdAt: DateTime.now(),
    );
    mockWalletRepo.wallets = [sampleWallet];
    mockWalletRepo.activeId = sampleWallet.id;
    mockWalletRepo.secrets[sampleWallet.id] = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    networkController = NetworkController(networkRepo);
    walletController = WalletController(repository: mockWalletRepo);
    languageController = LanguageController(localStorage);
    await walletController.loadWallets();

    assetController = AssetController(repository: AssetRepository(assetService: AssetService()));
    await assetController.loadAssets(
      network: networkController.allNetworks.first,
      walletAddress: sampleWallet.address,
      walletId: sampleWallet.id,
    );
  });

  Widget createTestApp(Widget child) {
    final envService = EnvironmentService();
    final envController = EnvironmentController(service: envService);
    final onChainService = OnChainTransactionService();

    return MultiProvider(
      providers: [
        Provider<IEnvironmentService>.value(value: envService),
        Provider<IOnChainTransactionService>.value(value: onChainService),
        Provider<ICryptoKeyService>.value(value: CryptoKeyService()),
        ChangeNotifierProvider<EnvironmentController>.value(value: envController),
        ChangeNotifierProvider<LanguageController>.value(value: languageController),
        ChangeNotifierProvider<NetworkController>.value(value: networkController),
        ChangeNotifierProvider<WalletController>.value(value: walletController),
        ChangeNotifierProvider<AssetController>.value(value: assetController),
        ChangeNotifierProvider<MarketController>(create: (_) => MarketController()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('WalletDetailsScreen renders identity, exports, and deletes wallet', (tester) async {
    await tester.pumpWidget(createTestApp(WalletDetailsScreen(wallet: sampleWallet)));
    await tester.pumpAndSettle();

    // Verify wallet details
    expect(find.text('Wallet Details'), findsOneWidget);
    expect(find.text('POL-1'), findsOneWidget);
    expect(find.text('Backup Recovery Phrase'), findsOneWidget);
    expect(find.text('Export Private Key'), findsOneWidget);
    expect(find.text('Export Keystore'), findsOneWidget);
    expect(find.text('Delete Wallet'), findsOneWidget);

    // Test Export Recovery Phrase modal
    await tester.tap(find.text('Backup Recovery Phrase'));
    await tester.pumpAndSettle();
    expect(find.text('Enter master password'), findsOneWidget);

    // Enter password and confirm
    await tester.enterText(find.byType(TextField), 'Password123');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Verify words shown
    expect(find.text('Recovery Phrase'), findsOneWidget);
    expect(find.text('Copy Recovery Phrase'), findsOneWidget);
    expect(find.text('abandon'), findsWidgets);

    // Close export modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Test Delete Wallet confirmation
    await tester.tap(find.text('Delete Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to delete this wallet? Make sure you have backed up the private key or recovery phrase.'), findsOneWidget);

    // Cancel deletion
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('SendScreen renders tokens, amount, gas fees and transfer confirmation', (tester) async {
    await tester.pumpWidget(createTestApp(const SendScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Send on'), findsOneWidget);
    expect(find.text('Recipient Address'), findsOneWidget);
    expect(find.text('Transfer Amount'), findsOneWidget);
    expect(find.text('Miner / Gas Fee'), findsOneWidget);
    expect(find.text('Slow'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Fast'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('ReceiveScreen renders QR Code and address copy', (tester) async {
    await tester.pumpWidget(createTestApp(const ReceiveScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Receive'), findsWidgets);
    expect(find.text('Copy Address'), findsOneWidget);
    expect(find.text('Set Amount'), findsOneWidget);
    expect(find.text('Share Address'), findsOneWidget);
    expect(find.text(sampleWallet.address), findsOneWidget);
  });

  testWidgets('SwapScreen renders Transit card, tabs, and flip button', (tester) async {
    await tester.pumpWidget(createTestApp(const SwapScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Transit Swap'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To (estimated)'), findsOneWidget);
    expect(find.text('Rate'), findsOneWidget);
    expect(find.text('Enter an Amount'), findsOneWidget);
  });

  testWidgets('MoreToolsScreen renders all TokenPocket utility categories', (tester) async {
    await tester.pumpWidget(createTestApp(const MoreToolsScreen()));
    await tester.pumpAndSettle();

    expect(find.text(languageController.tr('more_tools_title')), findsOneWidget);
    expect(find.text(languageController.tr('batch_transfer')), findsOneWidget);
    expect(find.text(languageController.tr('approval_revoke')), findsOneWidget);
    expect(find.text(languageController.tr('token_security')), findsOneWidget);
    expect(find.text(languageController.tr('rpc_switcher')), findsOneWidget);
    expect(find.text(languageController.tr('gas_tracker')), findsOneWidget);
    expect(find.text(languageController.tr('msg_signer')), findsOneWidget);
    expect(find.text(languageController.tr('security_audit')), findsOneWidget);
  });

  testWidgets('SearchHubScreen renders search bar, trending tags, and filters DApps & tokens', (tester) async {
    await tester.pumpWidget(createTestApp(const SearchHubScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Uniswap V3'), findsAtLeastNWidgets(1));

    // Type "Pancake" into search box
    await tester.enterText(find.byType(TextField), 'Pancake');
    await tester.pumpAndSettle();

    expect(find.text('PancakeSwap'), findsAtLeastNWidgets(1));
  });

  testWidgets('ScanQrScreen renders viewfinder, flashlight, and simulation sheet', (tester) async {
    await tester.pumpWidget(createTestApp(const ScanQrScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Scan QR Code'), findsOneWidget);
    expect(find.text('Place QR code within frame to scan'), findsOneWidget);
    expect(find.text('My QR Code'), findsOneWidget);
    expect(find.text('Simulate Scan'), findsOneWidget);

    // Tap Simulate Scan button
    await tester.tap(find.text('Simulate Scan'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('EVM Recipient Address'), findsOneWidget);
    expect(find.text('WalletConnect v2 URI'), findsOneWidget);
  });

  testWidgets('WalletDashboardScreen renders token list and opens Token Details Sheet upon tap', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const WalletDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('POL'), findsAtLeastNWidgets(1));

    // Tap on token row
    await tester.tap(find.text('POL').first);
    await tester.pumpAndSettle();

    // Verify Token Details Sheet opened with actions
    expect(find.text('POL • Polygon'), findsOneWidget);
    expect(find.text('Send'), findsAtLeastNWidgets(1));
    expect(find.text('Receive'), findsAtLeastNWidgets(1));
    expect(find.text('Swap'), findsAtLeastNWidgets(1));
  });

  testWidgets('WalletDashboardScreen opens Add / Manage Tokens modal sheet upon tapping (+) icon', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const WalletDashboardScreen()));
    await tester.pumpAndSettle();

    // Tap the (+) add token button
    await tester.tap(find.byKey(const Key('dashboard_add_token_button')));
    await tester.pumpAndSettle();

    expect(find.text('Add / Manage Tokens'), findsOneWidget);
    expect(find.text('Popular Tokens'), findsOneWidget);
    expect(find.text('Custom Token'), findsOneWidget);
  });

  testWidgets('WalletDashboardScreen opens Asset Filter dropdown upon tapping Assets tab', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(const WalletDashboardScreen()));
    await tester.pumpAndSettle();

    // Tap Assets ▾
    await tester.tap(find.text('Assets'));
    await tester.pumpAndSettle();

    expect(find.text('Filter Assets'), findsOneWidget);
    expect(find.text('Hide Small Balances (< \$1)'), findsOneWidget);
    expect(find.text('Sort by Balance'), findsOneWidget);
  });
}
