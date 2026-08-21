import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/presentation/screens/discover/discover_screen.dart';
import 'package:geniuswallet/presentation/screens/me/address_book_screen.dart';
import 'package:geniuswallet/presentation/screens/me/help_feedback_screen.dart';
import 'package:geniuswallet/presentation/screens/placeholder_screens.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/repositories/network_repository.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

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
      name: 'Tester Wallet',
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

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletController),
        ChangeNotifierProvider.value(value: networkController),
        ChangeNotifierProvider.value(value: assetController),
        ChangeNotifierProvider.value(value: languageController),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('DiscoverScreen Tests', () {
    testWidgets('Renders Discover Hub, Banners, and Category Chips', (tester) async {
      await tester.pumpWidget(createTestWidget(const DiscoverScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Uniswap V3'), findsOneWidget);
      expect(find.text('QuickSwap'), findsOneWidget);
      expect(find.text('Aave V3'), findsOneWidget);
      expect(find.text('OpenSea'), findsOneWidget);
    });

    testWidgets('Filtering by DeFi category shows DeFi DApps', (tester) async {
      await tester.pumpWidget(createTestWidget(const DiscoverScreen()));
      await tester.pumpAndSettle();

      // Tap DeFi category
      await tester.tap(find.text('DeFi').first);
      await tester.pumpAndSettle();

      expect(find.text('Uniswap V3'), findsOneWidget);
      expect(find.text('QuickSwap'), findsOneWidget);
      expect(find.text('OpenSea'), findsNothing);
    });
  });

  group('MeScreen and Sub-screens Tests', () {
    testWidgets('MeScreen renders profile header, Address Book, and Node Settings', (tester) async {
      await tester.pumpWidget(createTestWidget(const MeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tester Wallet'), findsOneWidget);
      expect(find.text('Address Book'), findsOneWidget);
      expect(find.text('Node Settings & Speed'), findsOneWidget);
      expect(find.text('Help & Feedback'), findsOneWidget);
    });

    testWidgets('AddressBookScreen renders contacts and allows modal interaction', (tester) async {
      await tester.pumpWidget(createTestWidget(const AddressBookScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Alice (Treasury)'), findsOneWidget);
      expect(find.text('Bob (DAO Member)'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('HelpFeedbackScreen displays FAQ and support details', (tester) async {
      await tester.pumpWidget(createTestWidget(const HelpFeedbackScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.text('Official Community'), findsOneWidget);
    });
  });
}
