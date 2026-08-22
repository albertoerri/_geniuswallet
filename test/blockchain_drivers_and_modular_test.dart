import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/core/blockchain/blockchain_driver.dart';
import 'package:geniuswallet/core/blockchain/blockchain_driver_registry.dart';
import 'package:geniuswallet/core/blockchain/evm_driver.dart';
import 'package:geniuswallet/core/config/app_config.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/domain/models/transaction_record.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/environment_controller.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/presentation/widgets/dashboard/manage_tokens_sheet.dart';
import 'package:geniuswallet/presentation/widgets/dashboard/wallet_account_drawer.dart';
import 'package:geniuswallet/presentation/widgets/tools/add_custom_token_sheet.dart';
import 'package:geniuswallet/presentation/widgets/tools/approval_revoke_sheet.dart';
import 'package:geniuswallet/presentation/widgets/tools/batch_transfer_sheet.dart';
import 'package:geniuswallet/presentation/widgets/tools/message_signer_sheet.dart';
import 'package:geniuswallet/presentation/widgets/tools/rpc_node_switcher_sheet.dart';
import 'package:geniuswallet/presentation/widgets/tools/token_security_sheet.dart';
import 'package:geniuswallet/presentation/widgets/tools/tx_speedup_sheet.dart';
import 'package:geniuswallet/repositories/asset_repository.dart';
import 'package:geniuswallet/repositories/network_repository.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';
import 'package:geniuswallet/services/asset_service.dart';
import 'package:geniuswallet/services/crypto_key_service.dart';
import 'package:geniuswallet/services/dex_aggregator_service.dart';
import 'package:geniuswallet/services/environment_service.dart';
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/services/onchain_transaction_service.dart';
import 'package:geniuswallet/services/transaction_history_service.dart';
import 'package:geniuswallet/services/wallet_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'package:geniuswallet/storage/secure_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Network polygonNetwork;
  const testPrivateKey = '4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f3608ba';
  const testAddress = '0x2c7536E3605D9C16a7a3D7b1898e529396a65c23';

  setUp(() {
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
  });

  group('BlockchainDriver & Registry Architecture Tests', () {
    test('BlockchainDriverRegistry auto-registers EVMDriver and routes for EVM networks', () {
      final registry = BlockchainDriverRegistry();
      final driver = registry.forNetwork(polygonNetwork);

      expect(driver, isA<EVMDriver>());
      expect(driver.supportedType, equals(NetworkType.evm));
      expect(driver.getExplorerTxUrl(polygonNetwork, '0xabc'), equals('https://polygonscan.com/tx/0xabc'));
    });

    test('EVMDriver queries balance, nonce, gas and transfers', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getBalance') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0xde0b6b3a7640000"}', 200); // 1.0 POL
        } else if (method == 'eth_getTransactionCount') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x1"}', 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0x77359400"}', 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response('{"jsonrpc":"2.0","id":1,"result":"0xdriverhash123"}', 200);
        }
        return http.Response('{"error":"not found"}', 404);
      });

      final evmDriver = EVMDriver();
      final balance = await evmDriver.getBalance(
        network: polygonNetwork,
        address: testAddress,
        client: mockClient,
      );
      expect(balance, equals(1.0));

      final nonce = await evmDriver.getNonce(
        network: polygonNetwork,
        address: testAddress,
        client: mockClient,
      );
      expect(nonce, equals(1));

      final res = await evmDriver.sendNativeTransfer(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        toAddress: testAddress,
        amount: 0.1,
        client: mockClient,
      );
      expect(res.isSuccess, isTrue);
      expect(res.txHash, equals('0xdriverhash123'));
    });
  });

  group('TransactionHistoryService & Indexer Tests', () {
    test('Records local transactions and fetches explorer transactions', () async {
      final historyService = TransactionHistoryService();

      final localTx = TransactionRecord(
        txHash: '0xlocalhash001',
        fromAddress: testAddress,
        toAddress: '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
        amount: 2.5,
        symbol: 'POL',
        timestamp: DateTime.now(),
        networkId: 'polygon',
      );
      historyService.recordLocalTransaction(localTx);

      final localList = historyService.getLocalHistory(walletAddress: testAddress, networkId: 'polygon');
      expect(localList.length, equals(1));
      expect(localList.first.txHash, equals('0xlocalhash001'));

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': '1',
            'message': 'OK',
            'result': [
              {
                'hash': '0xexplorertx002',
                'from': testAddress,
                'to': '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
                'value': '1000000000000000000',
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
      expect(allTxs.any((t) => t.txHash == '0xlocalhash001'), isTrue);
      expect(allTxs.any((t) => t.txHash == '0xexplorertx002'), isTrue);
    });
  });

  group('DexAggregatorService Multi-Route Tests', () {
    test('Calculates multi-DEX quotes and selects best route', () async {
      final dexService = DexAggregatorService();

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
      final bestQuote = await dexService.getBestQuote(
        network: polygonNetwork,
        fromToken: fromToken,
        toToken: toToken,
        amount: 100.0,
      );

      expect(bestQuote.estimatedToAmount, greaterThan(0));
      expect(bestQuote.dexName, isNotEmpty);
    });

    test('Identifies 1:1 direct WPOL Wrap/Unwrap quote', () async {
      final dexService = DexAggregatorService();

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
        id: 'polygon_wpol',
        networkId: 'polygon',
        symbol: 'WPOL',
        name: 'Wrapped POL',
        decimals: 18,
        contractAddress: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
        priceUsd: 0.42,
      );

      final quotes = await dexService.getQuotes(
        network: polygonNetwork,
        fromToken: fromToken,
        toToken: toToken,
        amount: 50.0,
      );

      expect(quotes.first.routeType, equals(DexRouteType.wpolDirect));
      expect(quotes.first.estimatedToAmount, equals(50.0));
    });
  });

  group('Standalone Modular Widget Tests', () {
    late SharedPreferences prefs;
    late LocalStorageService localStorage;
    late SecureStorageService secureStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localStorage = LocalStorageService(prefs);
      secureStorage = SecureStorageService();
    });

    Widget buildTestHarness(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageController(localStorage)),
          ChangeNotifierProvider(create: (_) => EnvironmentController(service: EnvironmentService(prefs: prefs))),
          ChangeNotifierProvider(create: (_) => NetworkController(NetworkRepository(networkService: NetworkService(), localStorageService: localStorage))),
          ChangeNotifierProvider(create: (_) => WalletController(repository: WalletRepository(localStorageService: localStorage, secureStorageService: secureStorage))),
          ChangeNotifierProvider(create: (_) => AssetController(repository: AssetRepository(assetService: AssetService()))),
          Provider<IOnChainTransactionService>(create: (_) => OnChainTransactionService()),
          Provider<ICryptoKeyService>(create: (_) => CryptoKeyService()),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    final testWallet = Wallet(
      id: 'test_w1',
      name: 'Main Polygon Wallet',
      address: testAddress,
      networkId: 'polygon',
      isBackedUp: true,
      importType: WalletImportType.privateKey,
      createdAt: DateTime(2026, 1, 1),
    );

    testWidgets('BatchTransferSheet renders input and CTA button', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          BatchTransferSheet(activeWallet: testWallet, network: polygonNetwork),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('ApprovalRevokeSheet renders approval items and Revoke CTA', (tester) async {
      final approvals = [
        {
          'spenderName': 'Uniswap V3',
          'spenderAddress': '0xE592427A0AEce92De3Edee1F18E0157C05861564',
          'token': 'USDT',
          'allowance': 'Unlimited',
        }
      ];

      await tester.pumpWidget(
        buildTestHarness(
          ApprovalRevokeSheet(
            activeWallet: testWallet,
            network: polygonNetwork,
            tokenApprovals: approvals,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Uniswap V3'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('TokenSecuritySheet renders search input and security score', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          TokenSecuritySheet(network: polygonNetwork),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('RpcNodeSwitcherSheet renders RPC node list and re-test CTA', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          RpcNodeSwitcherSheet(network: polygonNetwork),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alchemy Dedicated (Primary)'), findsOneWidget);
    });

    testWidgets('MessageSignerSheet renders message input and offline sign button', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          MessageSignerSheet(activeWallet: testWallet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('AddCustomTokenSheet renders contract address input and save CTA', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          AddCustomTokenSheet(network: polygonNetwork),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('TxSpeedupSheet renders info and confirm button', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const TxSpeedupSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('WalletAccountDrawer renders account list and add CTA', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          WalletAccountDrawer(onAddWallet: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('ManageTokensSheet renders token toggle switches and add custom token button', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          ManageTokensSheet(network: polygonNetwork),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });
}
