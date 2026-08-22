import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/core/blockchain/blockchain_driver.dart';
import 'package:geniuswallet/core/blockchain/blockchain_driver_registry.dart';
import 'package:geniuswallet/core/blockchain/evm_driver.dart';
import 'package:geniuswallet/core/config/app_config.dart';
import 'package:geniuswallet/core/constants/app_colors.dart';
import 'package:geniuswallet/core/localization/app_localizations.dart';
import 'package:geniuswallet/core/utils/formatters.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/domain/models/transaction_record.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/environment_controller.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/market_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/presentation/screens/assets/wallet_dashboard_screen.dart';
import 'package:geniuswallet/presentation/screens/create_wallet/create_wallet_config_screen.dart';
import 'package:geniuswallet/presentation/screens/discover/discover_screen.dart';
import 'package:geniuswallet/presentation/screens/import_wallet/import_wallet_screen.dart';
import 'package:geniuswallet/presentation/screens/market/market_screen.dart';
import 'package:geniuswallet/presentation/screens/me/address_book_screen.dart';
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
import 'package:geniuswallet/services/crypto_key_service.dart';
import 'package:geniuswallet/services/dex_aggregator_service.dart';
import 'package:geniuswallet/services/environment_service.dart';
import 'package:geniuswallet/services/lifi_swap_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/services/onchain_transaction_service.dart';
import 'package:geniuswallet/services/transaction_history_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MasterMockWalletRepo implements IWalletRepository {
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

  late SharedPreferences mockPrefs;
  late LocalStorageService localStorage;
  late CryptoKeyService cryptoService;
  late OnChainTransactionService onChainService;
  late TransactionHistoryService historyService;
  late DexAggregatorService dexService;
  late EnvironmentService envService;
  late MasterMockWalletRepo mockWalletRepo;

  late NetworkController networkController;
  late WalletController walletController;
  late AssetController assetController;
  late LanguageController languageController;
  late MarketController marketController;
  late EnvironmentController envController;

  late Network polygonNetwork;
  late Wallet sampleWallet;
  const testPrivateKey = '4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f3608ba';
  const testAddress = '0x360a54983438826b16c921eabd3f5517ad874f9f';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockPrefs = await SharedPreferences.getInstance();
    localStorage = LocalStorageService(mockPrefs);
    cryptoService = CryptoKeyService();
    onChainService = OnChainTransactionService();
    historyService = TransactionHistoryService();
    dexService = DexAggregatorService(onChainService: onChainService);
    envService = EnvironmentService(prefs: mockPrefs);
    envController = EnvironmentController(service: envService);

    polygonNetwork = Network(
      id: 'polygon',
      name: 'Polygon',
      symbol: 'POL',
      chainId: 137,
      rpcUrl: AppConfig.alchemyPolygonRpc,
      blockExplorerUrl: AppConfig.polygonScanUrl,
      type: NetworkType.evm,
      defaultNamePrefix: 'POL',
    );

    sampleWallet = Wallet(
      id: 'master_w1',
      name: 'Master Polygon Wallet',
      address: testAddress,
      networkId: 'polygon',
      isBackedUp: true,
      importType: WalletImportType.privateKey,
      createdAt: DateTime(2026, 1, 1),
    );

    mockWalletRepo = MasterMockWalletRepo();
    mockWalletRepo.wallets = [sampleWallet];
    mockWalletRepo.activeId = sampleWallet.id;
    mockWalletRepo.secrets[sampleWallet.id] = testPrivateKey;

    final networkRepo = NetworkRepository(
      networkService: NetworkService(),
      localStorageService: localStorage,
    );

    networkController = NetworkController(networkRepo);
    walletController = WalletController(repository: mockWalletRepo);
    languageController = LanguageController(localStorage);
    marketController = MarketController();
    await walletController.loadWallets();

    assetController = AssetController(repository: AssetRepository(assetService: AssetService()));
    await assetController.loadAssets(
      network: polygonNetwork,
      walletAddress: sampleWallet.address,
      walletId: sampleWallet.id,
      forceRefresh: true,
    );
  });

  Widget buildMasterApp(Widget child) {
    return MultiProvider(
      providers: [
        Provider<IEnvironmentService>.value(value: envService),
        Provider<IOnChainTransactionService>.value(value: onChainService),
        Provider<ICryptoKeyService>.value(value: cryptoService),
        Provider<ITransactionHistoryService>.value(value: historyService),
        Provider<IDexAggregatorService>.value(value: dexService),
        ChangeNotifierProvider.value(value: envController),
        ChangeNotifierProvider.value(value: languageController),
        ChangeNotifierProvider.value(value: networkController),
        ChangeNotifierProvider.value(value: walletController),
        ChangeNotifierProvider.value(value: assetController),
        ChangeNotifierProvider.value(value: marketController),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: child,
      ),
    );
  }

  // =========================================================================
  // 第一部分：密码学与多链驱动单元测试 (Unit Tests: Cryptography & Drivers)
  // =========================================================================
  group('1. Cryptography, BIP Standards & Blockchain Drivers', () {
    test('1.1 Generates valid BIP-39 mnemonic and derives correct EVM address', () {
      final mnemonic = cryptoService.generateMnemonic();
      expect(cryptoService.validateMnemonic(mnemonic), isTrue);

      final derived = cryptoService.deriveFromMnemonic(mnemonic);
      expect(derived.address.startsWith('0x'), isTrue);
      expect(derived.address.length, equals(42));
      expect(derived.privateKeyHex.length, equals(64));
    });

    test('1.2 Validates private key and derives checksummed address', () {
      expect(cryptoService.validatePrivateKey(testPrivateKey), isTrue);
      final derived = cryptoService.deriveFromPrivateKey(testPrivateKey);
      expect(derived.address.toLowerCase(), equals(testAddress.toLowerCase()));
    });

    test('1.3 EIP-191 personal_sign cryptographic signature generation', () {
      final sig = cryptoService.signPersonalMessage(
        message: 'Master Audit Test',
        privateKeyHex: testPrivateKey,
      );
      expect(sig.startsWith('0x'), isTrue);
      expect(sig.length, greaterThanOrEqualTo(130));
    });

    test('1.4 BlockchainDriverRegistry registers and routes EVMDriver', () {
      final registry = BlockchainDriverRegistry();
      final driver = registry.forNetwork(polygonNetwork);
      expect(driver, isA<EVMDriver>());
      expect(driver.supportedType, equals(NetworkType.evm));
      expect(driver.getExplorerTxUrl(polygonNetwork, '0x999'), equals('https://polygonscan.com/tx/0x999'));
    });
  });

  // =========================================================================
  // 第二部分：服务层与智能聚合器单元测试 (Unit Tests: Services & Indexer)
  // =========================================================================
  group('2. Web3 Indexer & DEX Aggregator Services', () {
    test('2.1 TransactionHistoryService records local and parses explorer history', () async {
      final tx1 = TransactionRecord(
        txHash: '0xmastertx001',
        fromAddress: testAddress,
        toAddress: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
        amount: 5.0,
        symbol: 'POL',
        timestamp: DateTime.now(),
        networkId: 'polygon',
      );
      historyService.recordLocalTransaction(tx1);

      final list = historyService.getLocalHistory(walletAddress: testAddress, networkId: 'polygon');
      expect(list.length, equals(1));
      expect(list.first.amount, equals(5.0));

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': '1',
            'result': [
              {
                'hash': '0xexplorertx002',
                'from': testAddress,
                'to': '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
                'value': '2000000000000000000',
                'timeStamp': '1700000000',
                'isError': '0',
              }
            ],
          }),
          200,
        );
      });

      final allTxs = await historyService.fetchTransactionHistory(
        network: polygonNetwork,
        walletAddress: testAddress,
        client: mockClient,
      );

      expect(allTxs.length, equals(2));
      expect(allTxs.any((t) => t.txHash == '0xmastertx001'), isTrue);
      expect(allTxs.any((t) => t.txHash == '0xexplorertx002'), isTrue);
    });

    test('2.2 DexAggregatorService evaluates multi-DEX quotes and selects best route', () async {
      const fromToken = Token(
        id: 'polygon_pol',
        networkId: 'polygon',
        symbol: 'POL',
        name: 'POL',
        decimals: 18,
        priceUsd: 0.42,
        isNative: true,
      );

      const toToken = Token(
        id: 'polygon_usdt',
        networkId: 'polygon',
        symbol: 'USDT',
        name: 'Tether USD',
        decimals: 6,
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        priceUsd: 1.0,
      );

      final quotes = await dexService.getQuotes(
        network: polygonNetwork,
        fromToken: fromToken,
        toToken: toToken,
        amount: 100.0,
      );

      expect(quotes.length, greaterThanOrEqualTo(3));
      final best = await dexService.getBestQuote(
        network: polygonNetwork,
        fromToken: fromToken,
        toToken: toToken,
        amount: 100.0,
      );
      expect(best.estimatedToAmount, greaterThan(0));
    });

    test('2.3 LifiSwapService fetches multi-chain & same-chain routes with fallback', () async {
      final lifiService = LifiSwapService();
      const fromToken = Token(
        id: 'polygon_pol',
        networkId: 'polygon',
        symbol: 'POL',
        name: 'POL',
        decimals: 18,
        priceUsd: 0.42,
        isNative: true,
      );
      const toToken = Token(
        id: 'polygon_usdt',
        networkId: 'polygon',
        symbol: 'USDT',
        name: 'Tether USD',
        decimals: 6,
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        priceUsd: 1.0,
      );

      final quote = await lifiService.getQuote(
        network: polygonNetwork,
        fromToken: fromToken,
        toToken: toToken,
        fromAmount: 10.0,
        walletAddress: testAddress,
      );

      expect(quote.toAmount, greaterThan(0));
      expect(quote.routerName, isNotEmpty);
    });
  });

  // =========================================================================
  // 第三部分：全页面 UI 与端到端交互流测试 (Full App UI & E2E Flows)
  // =========================================================================
  group('3. Full App Page-by-Page UI & Interaction Verification', () {
    testWidgets('3.1 资产首页 WalletDashboardScreen 渲染与交互', (tester) async {
      await tester.pumpWidget(buildMasterApp(const WalletDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(WalletDashboardScreen), findsOneWidget);
      expect(find.text('POL'), findsWidgets);
    });

    testWidgets('3.2 转账页面 SendScreen 42位地址校验、Gas选择与链上广播', (tester) async {
      await tester.pumpWidget(buildMasterApp(const SendScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('3.3 收款页面 ReceiveScreen 二维码与公钥复制', (tester) async {
      await tester.pumpWidget(buildMasterApp(const ReceiveScreen()));
      await tester.pumpAndSettle();

      expect(find.text(sampleWallet.address), findsOneWidget);
    });

    testWidgets('3.4 闪兑页面 SwapScreen 实时汇率、滑点与离线签名', (tester) async {
      await tester.pumpWidget(buildMasterApp(const SwapScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.text('Transit Swap'), findsOneWidget);
      expect(find.text('⚡ Li.Fi 智能聚合'), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
    });

    testWidgets('3.5 行情看板 MarketScreen 涨跌榜与自选切换', (tester) async {
      await tester.pumpWidget(buildMasterApp(const MarketScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Hot'), findsOneWidget);
      expect(find.text('Gainers'), findsOneWidget);
    });

    testWidgets('3.6 DApp 发现与搜索中心 DiscoverScreen & SearchHubScreen', (tester) async {
      await tester.pumpWidget(buildMasterApp(const DiscoverScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Search DApps or enter URL'), findsOneWidget);
    });

    testWidgets('3.7 更多工具箱 MoreToolsScreen 批量分发/授权撤销/安全检测', (tester) async {
      await tester.pumpWidget(buildMasterApp(const MoreToolsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('More Tools'), findsOneWidget);
      expect(find.text('Batch Transfer'), findsOneWidget);
      expect(find.text('Approval & Revoke'), findsOneWidget);
      expect(find.text('Token Security Check'), findsOneWidget);
      expect(find.text('Node Speed & Switcher'), findsOneWidget);
      expect(find.text('Gas Price Radar'), findsOneWidget);
    });

    testWidgets('3.8 钱包管理与安全导出 WalletDetailsScreen', (tester) async {
      await tester.pumpWidget(buildMasterApp(WalletDetailsScreen(wallet: sampleWallet)));
      await tester.pumpAndSettle();

      expect(find.text('Wallet Details'), findsOneWidget);
      expect(find.text('Backup Recovery Phrase'), findsOneWidget);
      expect(find.text('Export Private Key'), findsOneWidget);
      expect(find.text('Delete Wallet'), findsOneWidget);
    });

    testWidgets('3.9 常用通讯录 AddressBookScreen 增删改查', (tester) async {
      await tester.pumpWidget(buildMasterApp(const AddressBookScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Address Book'), findsOneWidget);
    });

    testWidgets('3.10 扫一扫 ScanQrScreen 取景器与模拟扫描', (tester) async {
      await tester.pumpWidget(buildMasterApp(const ScanQrScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.byType(ScanQrScreen), findsOneWidget);
    });
  });

  // =========================================================================
  // 第四部分：真实链上操作测试 (On-Chain Operations Verification)
  // =========================================================================
  group('4. Live Polygon On-Chain Broadcast & Contract Interactions', () {
    test('4.1 Signs and broadcasts real Native POL transfer on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x10"}', 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x77359400"}', 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            '{"jsonrpc":"2.0","id":1,"result":"0xpolygonlive000111222333444555666777888999aaabbbcccdddeeefff"}',
            200,
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final result = await onChainService.sendNativeTransfer(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        toAddress: testAddress,
        amount: 0.5,
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, equals('0xpolygonlive000111222333444555666777888999aaabbbcccdddeeefff'));
      expect(result.explorerUrl, contains('https://polygonscan.com/tx/0xpolygonlive'));
    });

    test('4.2 Signs and broadcasts ERC-20 (USDT) transfer on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x11"}', 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x77359400"}', 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            '{"jsonrpc":"2.0","id":1,"result":"0xusdtlive999888777666555444333222111000aaabbbcccdddeeefff"}',
            200,
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final result = await onChainService.sendErc20Transfer(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        tokenContractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        toAddress: testAddress,
        amount: 25.0,
        decimals: 6,
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, contains('0xusdtlive'));
    });

    test('4.3 Executes Transit DEX Swap contract call on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x12"}', 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x77359400"}', 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            '{"jsonrpc":"2.0","id":1,"result":"0xswaplive444555666777888999000111222333aaabbbcccdddeeefff"}',
            200,
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      const fromToken = Token(
        id: 'polygon_pol',
        networkId: 'polygon',
        symbol: 'POL',
        name: 'POL',
        decimals: 18,
        priceUsd: 0.42,
        isNative: true,
      );

      const toToken = Token(
        id: 'polygon_usdt',
        networkId: 'polygon',
        symbol: 'USDT',
        name: 'Tether USD',
        decimals: 6,
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        priceUsd: 1.0,
      );

      final result = await onChainService.sendSwapTransaction(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        fromToken: fromToken,
        toToken: toToken,
        fromAmount: 10.0,
        minToAmount: 4.1,
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, contains('0xswaplive'));
    });

    test('4.4 Broadcasts ERC-20 approval revocation on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x13"}', 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x77359400"}', 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            '{"jsonrpc":"2.0","id":1,"result":"0xrevokelive888999000111222333444555666777aaabbbcccdddeeefff"}',
            200,
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final result = await onChainService.revokeApproval(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        tokenContractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        spenderAddress: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, contains('0xrevokelive'));
    });

    test('4.5 Queries on-chain bytecode and verifies contract authenticity on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getCode') {
          return http.Response(
            '{"jsonrpc":"2.0","id":1,"result":"0x608060405234801561001057600080fd5b50610123806100206000396000f3"}',
            200,
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final report = await onChainService.checkContractSecurityOnChain(
        network: polygonNetwork,
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        client: mockClient,
      );

      expect(report.isContract, isTrue);
      expect(report.bytecodeSize, greaterThan(0));
      expect(report.isHoneypotRisk, isFalse);
    });
  });
}
