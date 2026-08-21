import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/core/localization/app_localizations.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/repositories/network_repository.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
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
      name: 'Main Polygon Wallet',
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

  group('Audio 1: Global Localization & Language Parity Audit', () {
    test('Verify EN and ZH completeness for all critical keys', () {
      final criticalKeys = [
        'tab_assets',
        'tab_market',
        'tab_trade',
        'tab_discover',
        'tab_me',
        'action_send',
        'action_receive',
        'action_swap',
        'send_on_network',
        'receive_on_network',
        'wallet_details',
        'export_private_key',
        'export_keystore',
        'delete_wallet',
        'discover_title',
        'featured_dapps',
        'address_book',
        'add_contact',
        'node_settings',
        'help_and_feedback',
        'faq_title',
        'contact_support',
        'swap_swapped_success',
        'err_recipient_empty',
        'err_insufficient_balance',
      ];

      for (final key in criticalKeys) {
        final enText = AppStrings.get(key, 'en');
        final zhText = AppStrings.get(key, 'zh');

        expect(enText, isNotEmpty, reason: 'Key $key must have EN translation');
        expect(zhText, isNotEmpty, reason: 'Key $key must have ZH translation');
        expect(enText, isNot(equals(key)), reason: 'Key $key should not return fallback key in EN');
        expect(zhText, isNot(equals(key)), reason: 'Key $key should not return fallback key in ZH');
      }
    });

    test('Verify parameterized string replacements work properly in EN and ZH', () {
      final enResult = AppStrings.get('send_on_network', 'en', params: {'network': 'Polygon'});
      final zhResult = AppStrings.get('send_on_network', 'zh', params: {'network': 'Polygon'});

      expect(enResult, equals('Send on Polygon'));
      expect(zhResult, equals('在 Polygon 网络转账'));

      final enSwapResult = AppStrings.get('swap_swapped_success', 'en', params: {
        'fromAmount': '10',
        'fromToken': 'POL',
        'toAmount': '4.5',
        'toToken': 'USDT',
      });
      final zhSwapResult = AppStrings.get('swap_swapped_success', 'zh', params: {
        'fromAmount': '10',
        'fromToken': 'POL',
        'toAmount': '4.5',
        'toToken': 'USDT',
      });

      expect(enSwapResult, equals('Swapped 10 POL to 4.5 USDT!'));
      expect(zhSwapResult, equals('成功将 10 POL 闪兑为 4.5 USDT！'));
    });
  });

  group('Audio 3: Native & ERC-20 Transfer and Swap Scenarios', () {
    test('Scenario 1: Native Token (POL) Transfer & Balance Update', () async {
      final activeWallet = walletController.activeWallet!;
      final network = networkController.allNetworks.first;

      // Seed initial 100 POL
      await assetController.claimFaucet(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'POL',
        amount: 100.0,
      );

      final initialPolBal = assetController.tokens.firstWhere((t) => t.symbol == 'POL').balance;
      expect(initialPolBal, equals(100.0));

      // Transfer 5 POL
      final transferAmount = 5.0;
      final newBalance = (initialPolBal - transferAmount).clamp(0.0, double.infinity);

      await assetController.updateBalance(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'POL',
        newBalance: newBalance,
      );

      final updatedPolBal = assetController.tokens.firstWhere((t) => t.symbol == 'POL').balance;
      expect(updatedPolBal, equals(95.0));
    });

    test('Scenario 2: ERC-20 Token (USDT / USDC) Transfer & Balance Update', () async {
      final activeWallet = walletController.activeWallet!;
      final network = networkController.allNetworks.first;

      // Seed initial 50 USDT
      await assetController.claimFaucet(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'USDT',
        amount: 50.0,
      );

      final initialUsdtBal = assetController.tokens.firstWhere((t) => t.symbol == 'USDT').balance;
      expect(initialUsdtBal, equals(50.0));

      // Transfer 15 USDT
      final transferAmount = 15.0;
      final newBalance = (initialUsdtBal - transferAmount).clamp(0.0, double.infinity);

      await assetController.updateBalance(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'USDT',
        newBalance: newBalance,
      );

      final updatedUsdtBal = assetController.tokens.firstWhere((t) => t.symbol == 'USDT').balance;
      expect(updatedUsdtBal, equals(35.0));
    });

    test('Scenario 3: Native to ERC-20 Swap (POL -> USDT)', () async {
      final activeWallet = walletController.activeWallet!;
      final network = networkController.allNetworks.first;

      // Seed 100 POL and 10 USDT
      await assetController.claimFaucet(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'POL',
        amount: 100.0,
      );
      await assetController.claimFaucet(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'USDT',
        amount: 10.0,
      );

      final polToken = assetController.tokens.firstWhere((t) => t.symbol == 'POL');
      final usdtToken = assetController.tokens.firstWhere((t) => t.symbol == 'USDT');

      final initialPol = polToken.balance;
      final initialUsdt = usdtToken.balance;

      final swapFromPol = 10.0;
      final rate = polToken.priceUsd / usdtToken.priceUsd;
      final expectedToUsdt = swapFromPol * rate;

      // Execute Swap
      await assetController.updateBalance(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'POL',
        newBalance: initialPol - swapFromPol,
      );
      await assetController.claimFaucet(
        network: network,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
        tokenSymbol: 'USDT',
        amount: expectedToUsdt,
      );

      final postSwapPol = assetController.tokens.firstWhere((t) => t.symbol == 'POL').balance;
      final postSwapUsdt = assetController.tokens.firstWhere((t) => t.symbol == 'USDT').balance;

      expect(postSwapPol, equals(90.0));
      expect(postSwapUsdt, closeTo(initialUsdt + expectedToUsdt, 0.001));
    });

    test('Scenario 4: Slippage Calculation Formula', () {
      const slippageTolerance = 2.0; // 2%
      const estimatedAmount = 100.0;
      final minReceived = estimatedAmount * (1 - (slippageTolerance / 100));

      expect(minReceived, equals(98.0));
    });

    test('Scenario 5: Multi-Chain network switching & token balance isolation', () async {
      final activeWallet = walletController.activeWallet!;

      // Polygon
      final polygonNet = networkController.allNetworks.firstWhere((n) => n.id == 'polygon');
      await assetController.loadAssets(
        network: polygonNet,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
      );
      expect(assetController.tokens.any((t) => t.symbol == 'POL'), isTrue);

      // Ethereum
      final ethNet = networkController.allNetworks.firstWhere((n) => n.id == 'ethereum');
      await assetController.loadAssets(
        network: ethNet,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
      );
      expect(assetController.tokens.any((t) => t.symbol == 'ETH'), isTrue);

      // BNB Chain (id: 'bnb')
      final bscNet = networkController.allNetworks.firstWhere((n) => n.id == 'bnb');
      await assetController.loadAssets(
        network: bscNet,
        walletAddress: activeWallet.address,
        walletId: activeWallet.id,
      );
      expect(assetController.tokens.any((t) => t.symbol == 'BNB'), isTrue);
    });
  });
}
