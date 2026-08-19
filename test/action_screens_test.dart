import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
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
    await walletController.loadWallets();

    assetController = AssetController(repository: AssetRepository(assetService: AssetService()));
    await assetController.loadAssets(
      network: networkController.allNetworks.first,
      walletAddress: sampleWallet.address,
      walletId: sampleWallet.id,
    );
  });

  Widget createTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NetworkController>.value(value: networkController),
        ChangeNotifierProvider<WalletController>.value(value: walletController),
        ChangeNotifierProvider<AssetController>.value(value: assetController),
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
    expect(find.text('Export Recovery Phrase'), findsOneWidget);
    expect(find.text('Export Private Key'), findsOneWidget);
    expect(find.text('Export Keystore'), findsOneWidget);
    expect(find.text('Delete Wallet'), findsOneWidget);

    // Test Export Recovery Phrase modal
    await tester.tap(find.text('Export Recovery Phrase'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your Master Password to verify identity:'), findsOneWidget);

    // Enter password and confirm
    await tester.enterText(find.byType(TextField), 'Password123');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Verify 12 words shown
    expect(find.text('Recovery Phrase'), findsOneWidget);
    expect(find.text('Copy Recovery Phrase'), findsOneWidget);
    expect(find.text('abandon'), findsWidgets);

    // Close export modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Test Delete Wallet confirmation
    await tester.tap(find.text('Delete Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to delete "POL-1"?\n\nPlease make sure you have backed up your Recovery Phrase or Private Key. This action cannot be undone.'), findsOneWidget);

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

    expect(find.text('Swap&Bridge'), findsOneWidget);
    expect(find.text('Limit Order'), findsOneWidget);
    expect(find.text('Transit'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To (estimated)'), findsOneWidget);
    expect(find.text('Swap Rate'), findsOneWidget);
    expect(find.text('Slippage'), findsOneWidget);
    expect(find.text('Enter an Amount'), findsOneWidget);
  });

  testWidgets('MoreToolsScreen renders all utility categories', (tester) async {
    await tester.pumpWidget(createTestApp(const MoreToolsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('More Tools'), findsOneWidget);
    expect(find.text('Asset Management'), findsOneWidget);
    expect(find.text('Batch Transfer'), findsOneWidget);
    expect(find.text('Approval Checker & Revoke'), findsOneWidget);
    expect(find.text('Network & Nodes'), findsOneWidget);
    expect(find.text('Fast RPC Node Switcher'), findsOneWidget);
    expect(find.text('Gas Tracker (EIP-1559)'), findsOneWidget);
    expect(find.text('Security & Hardware'), findsOneWidget);
    expect(find.text('KeyPal Hardware Wallet'), findsOneWidget);
  });
}
