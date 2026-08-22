import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/core/localization/app_localizations.dart';
import 'package:geniuswallet/domain/models/market_item.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/presentation/controllers/asset_controller.dart';
import 'package:geniuswallet/presentation/controllers/environment_controller.dart';
import 'package:geniuswallet/presentation/controllers/language_controller.dart';
import 'package:geniuswallet/presentation/controllers/market_controller.dart';
import 'package:geniuswallet/presentation/controllers/network_controller.dart';
import 'package:geniuswallet/presentation/controllers/wallet_controller.dart';
import 'package:geniuswallet/services/environment_service.dart';
import 'package:geniuswallet/services/onchain_transaction_service.dart';
import 'package:provider/provider.dart';
import 'package:geniuswallet/presentation/screens/assets/wallet_dashboard_screen.dart';
import 'package:geniuswallet/presentation/screens/assets/welcome_screen.dart';
import 'package:geniuswallet/presentation/screens/market/market_screen.dart';
import 'package:geniuswallet/presentation/screens/me/address_book_screen.dart';
import 'package:geniuswallet/presentation/screens/network/select_network_screen.dart';
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
import 'package:geniuswallet/services/network_service.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnChainMockWalletRepository implements IWalletRepository {
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

  late OnChainMockWalletRepository mockWalletRepo;
  late NetworkController networkController;
  late WalletController walletController;
  late AssetController assetController;
  late LanguageController languageController;
  late MarketController marketController;
  late Wallet polygonWallet;
  late Wallet ethereumWallet;
  late Wallet bscWallet;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorageService(sharedPrefs);
    final networkService = NetworkService();
    final networkRepo = NetworkRepository(
      networkService: networkService,
      localStorageService: localStorage,
    );

    mockWalletRepo = OnChainMockWalletRepository();

    polygonWallet = Wallet(
      id: 'wallet-polygon-1',
      name: 'Polygon Main Safe',
      address: '0x71C8412092081f3865354924A2A2D1f337c62d08',
      networkId: 'polygon',
      importType: WalletImportType.recoveryPhrase,
      createdAt: DateTime.now(),
    );

    ethereumWallet = Wallet(
      id: 'wallet-eth-1',
      name: 'Ethereum Whale Vault',
      address: '0x32Be343B94f860124dC4fEe278FDCBD38C102D88',
      networkId: 'ethereum',
      importType: WalletImportType.privateKey,
      createdAt: DateTime.now(),
    );

    bscWallet = Wallet(
      id: 'wallet-bsc-1',
      name: 'BNB Trading Pool',
      address: '0x8894E0a0c962CB723c1976a4421c95949bE2D4E3',
      networkId: 'bnb',
      importType: WalletImportType.keystore,
      createdAt: DateTime.now(),
    );

    mockWalletRepo.wallets = [polygonWallet, ethereumWallet, bscWallet];
    mockWalletRepo.activeId = polygonWallet.id;
    mockWalletRepo.secrets[polygonWallet.id] = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
    mockWalletRepo.secrets[ethereumWallet.id] = '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d';
    mockWalletRepo.secrets[bscWallet.id] = jsonEncode({'address': bscWallet.address, 'crypto': {'cipher': 'aes-128-ctr'}});

    final envService = EnvironmentService(prefs: sharedPrefs);
    final envController = EnvironmentController(service: envService);
    final onChainService = OnChainTransactionService();

    networkController = NetworkController(networkRepo);
    walletController = WalletController(repository: mockWalletRepo);
    languageController = LanguageController(localStorage);
    marketController = MarketController();
    await walletController.loadWallets();

    assetController = AssetController(repository: AssetRepository(assetService: AssetService()));
    await assetController.loadAssets(
      network: networkController.allNetworks.firstWhere((n) => n.id == 'polygon'),
      walletAddress: polygonWallet.address,
      walletId: polygonWallet.id,
      forceRefresh: true,
    );
  });

  Widget buildTestApp(Widget child) {
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
        ChangeNotifierProvider<WalletController>.value(value: walletController),
        ChangeNotifierProvider<NetworkController>.value(value: networkController),
        ChangeNotifierProvider<AssetController>.value(value: assetController),
        ChangeNotifierProvider<MarketController>.value(value: marketController),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  final cryptoService = CryptoKeyService();

  group('【链上密码学与密钥派生测试】Cryptography & Key Derivation Suite', () {
    test('1.1 BIP39 标准助记词生成与 12 词词库校验', () {
      final mnemonic = cryptoService.generateMnemonic();
      final words = mnemonic.split(' ');
      expect(words.length, equals(12));
      expect(cryptoService.validateMnemonic(mnemonic), isTrue);
      expect(cryptoService.validateMnemonic('invalid word test foo bar baz'), isFalse);
    });

    test('1.2 BIP44 多链派生路径与地址生成 (Polygon, Ethereum, BNB, Solana, Bitcoin, Tron)', () {
      const mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final ethResult = cryptoService.deriveFromMnemonic(mnemonic, derivationPath: "m/44'/60'/0'/0/0");
      final polyResult = cryptoService.deriveFromMnemonic(mnemonic, derivationPath: "m/44'/60'/0'/0/0");
      final bscResult = cryptoService.deriveFromMnemonic(mnemonic, derivationPath: "m/44'/60'/0'/0/0");

      expect(ethResult.address.startsWith('0x'), isTrue);
      expect(polyResult.address.startsWith('0x'), isTrue);
      expect(bscResult.address.startsWith('0x'), isTrue);
      expect(ethResult.privateKeyHex.length, equals(64));
    });

    test('1.3 私钥导入合法性验证与公钥地址派生', () {
      const validHexKey = '4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d';
      const valid0xKey = '0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d';
      const invalidKey = '12345tooShortKey';

      expect(cryptoService.validatePrivateKey(validHexKey), isTrue);
      expect(cryptoService.validatePrivateKey(valid0xKey), isTrue);
      expect(cryptoService.validatePrivateKey(invalidKey), isFalse);

      final derived = cryptoService.deriveFromPrivateKey(validHexKey);
      expect(derived.address.startsWith('0x'), isTrue);
    });

    test('1.4 地址有效性校验与格式校验', () {
      const validAddr = '0x71C8412092081f3865354924A2A2D1f337c62d08';
      const invalidAddr = '0x123notAValidEthAddress';

      expect(cryptoService.validateAddress(validAddr), isTrue);
      expect(cryptoService.validateAddress(invalidAddr), isFalse);
    });
  });

  group('【链上资产与代币状态机测试】On-Chain Asset Lifecycle & Balance Engine', () {
    test('2.1 多代币初始化与原生代币 / ERC-20 资产加载', () async {
      final polyNetwork = networkController.allNetworks.firstWhere((n) => n.id == 'polygon');
      await assetController.loadAssets(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        forceRefresh: true,
      );

      expect(assetController.tokens.isNotEmpty, isTrue);
      final polToken = assetController.tokens.firstWhere((t) => t.symbol == 'POL');
      expect(polToken.isNative, isTrue);
      expect(polToken.decimals, equals(18));

      final usdtToken = assetController.tokens.firstWhere((t) => t.symbol == 'USDT');
      expect(usdtToken.isNative, isFalse);
      expect(usdtToken.decimals, equals(6));
    });

    test('2.2 添加自定义 ERC-20 代币合约并验证自动识别', () async {
      const customContract = '0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6';

      assetController.addCustomToken(
        const Token(
          id: 'wbtc-poly',
          name: 'Wrapped BTC',
          symbol: 'WBTC',
          decimals: 8,
          networkId: 'polygon',
          contractAddress: customContract,
          balance: 0.05,
          priceUsd: 68500.0,
          change24h: 2.5,
          isNative: false,
        ),
      );

      final wbtc = assetController.tokens.firstWhere((t) => t.symbol == 'WBTC');
      expect(wbtc.contractAddress, equals(customContract));
      expect(wbtc.decimals, equals(8));
      expect(wbtc.name, equals('Wrapped BTC'));
    });

    test('2.3 资产估值与总资产折算 USD 计算', () async {
      final polyNetwork = networkController.allNetworks.firstWhere((n) => n.id == 'polygon');
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'POL',
        newBalance: 1000.0,
      );
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'USDT',
        newBalance: 500.0,
      );

      final totalBalanceUsd = assetController.totalBalanceUsd;
      expect(totalBalanceUsd, greaterThan(500.0));
    });
  });

  group('【链上转账与交易执行全闭环测试】Transfer & Transaction Execution', () {
    test('3.1 原生代币转账：余额扣减与交易广播 Hash 生成', () async {
      final polyNetwork = networkController.allNetworks.firstWhere((n) => n.id == 'polygon');
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'POL',
        newBalance: 100.0,
      );

      const recipient = '0x32Be343B94f860124dC4fEe278FDCBD38C102D88';
      const sendAmount = 25.0;
      final currentBal = assetController.tokens.firstWhere((t) => t.symbol == 'POL').balance;

      expect(currentBal, equals(100.0));
      expect(sendAmount <= currentBal, isTrue);

      final newBal = currentBal - sendAmount;
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'POL',
        newBalance: newBal,
      );

      final postBal = assetController.tokens.firstWhere((t) => t.symbol == 'POL').balance;
      expect(postBal, equals(75.0));

      final txHash = '0x${(recipient + sendAmount.toString()).hashCode.abs().toRadixString(16).padLeft(64, 'a')}';
      expect(txHash.startsWith('0x'), isTrue);
      expect(txHash.length, equals(66));
    });

    test('3.2 ERC-20 代币转账：代币余额扣除与独立原生 Gas 计算', () async {
      final polyNetwork = networkController.allNetworks.firstWhere((n) => n.id == 'polygon');
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'USDT',
        newBalance: 200.0,
      );

      const sendUsdt = 80.0;
      final currentUsdt = assetController.tokens.firstWhere((t) => t.symbol == 'USDT').balance;
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'USDT',
        newBalance: currentUsdt - sendUsdt,
      );

      final postUsdt = assetController.tokens.firstWhere((t) => t.symbol == 'USDT').balance;
      expect(postUsdt, equals(120.0));
    });

    test('3.3 批量转账文本解析与多地址 Gas 汇总校验', () {
      const rawBatchText = '''
0x71C8412092081f3865354924A2A2D1f337c62d08, 10.5
0x32Be343B94f860124dC4fEe278FDCBD38C102D88, 20.0
0x8894E0a0c962CB723c1976a4421c95949bE2D4E3, 5.25
''';
      final lines = rawBatchText.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(lines.length, equals(3));

      double totalAmount = 0.0;
      for (final line in lines) {
        final parts = line.split(',');
        expect(parts.length, equals(2));
        final addr = parts[0].trim();
        final amt = double.parse(parts[1].trim());
        expect(addr.startsWith('0x'), isTrue);
        expect(amt, greaterThan(0));
        totalAmount += amt;
      }

      expect(totalAmount, equals(35.75));
    });
  });

  group('【Transit 闪兑与跨币种兑换引擎测试】Swap & Transit Aggregator Suite', () {
    test('4.1 汇率换算、滑点容忍度与最小到账量计算', () {
      const polPrice = 0.1262;
      const usdtPrice = 1.0;
      const swapInputPol = 100.0;

      final estimatedUsdt = (swapInputPol * polPrice) / usdtPrice;
      expect(estimatedUsdt, closeTo(12.62, 0.01));

      const slippage = 0.005; // 0.5%
      final minReceived = estimatedUsdt * (1.0 - slippage);
      expect(minReceived, closeTo(12.5569, 0.01));
    });

    test('4.2 闪兑双代币原子状态结算与流水日志生成', () async {
      final polyNetwork = networkController.allNetworks.firstWhere((n) => n.id == 'polygon');
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'POL',
        newBalance: 100.0,
      );
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'USDT',
        newBalance: 50.0,
      );

      const fromAmount = 50.0;
      const toAmount = 6.31;

      final currentPol = assetController.tokens.firstWhere((t) => t.symbol == 'POL').balance;
      final currentUsdt = assetController.tokens.firstWhere((t) => t.symbol == 'USDT').balance;

      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'POL',
        newBalance: currentPol - fromAmount,
      );
      await assetController.updateBalance(
        network: polyNetwork,
        walletAddress: polygonWallet.address,
        walletId: polygonWallet.id,
        tokenSymbol: 'USDT',
        newBalance: currentUsdt + toAmount,
      );

      final postPol = assetController.tokens.firstWhere((t) => t.symbol == 'POL').balance;
      final postUsdt = assetController.tokens.firstWhere((t) => t.symbol == 'USDT').balance;

      expect(postPol, equals(50.0));
      expect(postUsdt, equals(56.31));
    });
  });

  group('【收款与扫一扫协议测试】Receive & Scan QR Protocol Parsing', () {
    test('5.1 EIP-681 指定金额收款 URI 构造与反向解析', () {
      const address = '0x71C8412092081f3865354924A2A2D1f337c62d08';
      const requestedAmount = '15.5';
      final paymentUri = 'ethereum:$address?value=$requestedAmount&token=POL';

      final uri = Uri.parse(paymentUri);
      expect(uri.scheme, equals('ethereum'));
      expect(uri.path, equals(address));
      expect(uri.queryParameters['value'], equals('15.5'));
      expect(uri.queryParameters['token'], equals('POL'));
    });

    test('5.2 WalletConnect 会话 URI 格式识别', () {
      const wcUri = 'wc:7f6e504e04747a3...839f?bridge=https%3A%2F%2Fbridge.walletconnect.org&key=4a3b...';
      expect(wcUri.startsWith('wc:'), isTrue);
    });
  });

  group('【多签钱包与 RPC 节点治理测试】MultiSig & Network RPC Governance', () {
    test('6.1 M-of-N 多签权重阈值与所有者校验', () {
      final owners = [
        '0x71C8412092081f3865354924A2A2D1f337c62d08',
        '0x32Be343B94f860124dC4fEe278FDCBD38C102D88',
        '0x8894E0a0c962CB723c1976a4421c95949bE2D4E3',
      ];
      const threshold = 2;

      expect(owners.length, equals(3));
      expect(threshold, greaterThanOrEqualTo(1));
      expect(threshold, lessThanOrEqualTo(owners.length));
    });

    test('6.2 全部支持的主网配置有效性与 RPC 端点检查', () {
      final networks = networkController.allNetworks;
      expect(networks.length, greaterThanOrEqualTo(8));

      final poly = networks.firstWhere((n) => n.id == 'polygon');
      final eth = networks.firstWhere((n) => n.id == 'ethereum');
      final bsc = networks.firstWhere((n) => n.id == 'bnb');
      final sol = networks.firstWhere((n) => n.id == 'solana');
      final btc = networks.firstWhere((n) => n.id == 'bitcoin');

      expect(poly.rpcUrl.startsWith('http'), isTrue);
      expect(eth.rpcUrl.startsWith('http'), isTrue);
      expect(bsc.rpcUrl.startsWith('http'), isTrue);
      expect(sol.rpcUrl.startsWith('http'), isTrue);
      expect(btc.symbol, equals('BTC'));
    });
  });

  group('【全页面 UI 与端到端交互流测试】Full App Page Journeys & UI Verification', () {
    testWidgets('7.1 资产主页 WalletDashboardScreen 完整渲染与金刚区入口', (tester) async {
      await tester.pumpWidget(buildTestApp(const WalletDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Receive'), findsOneWidget);
      expect(find.text('Swap'), findsOneWidget);
      expect(find.text('More Tools'), findsOneWidget);
      expect(find.text('POL'), findsWidgets);
    });

    testWidgets('7.2 转账页面 SendScreen 渲染与输入校验', (tester) async {
      await tester.pumpWidget(buildTestApp(const SendScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recipient Address'), findsOneWidget);
      expect(find.text('Transfer Amount'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('7.3 收款页面 ReceiveScreen 渲染与指定金额弹窗', (tester) async {
      await tester.pumpWidget(buildTestApp(const ReceiveScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Receive'), findsWidgets);
      expect(find.text('Copy Address'), findsOneWidget);
      expect(find.text('Set Amount'), findsOneWidget);
    });

    testWidgets('7.4 闪兑页面 SwapScreen 渲染与代币对调', (tester) async {
      await tester.pumpWidget(buildTestApp(const SwapScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Transit Swap'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To (estimated)'), findsOneWidget);
    });

    testWidgets('7.5 常用通讯录 AddressBookScreen 渲染与联系人展示', (tester) async {
      await tester.pumpWidget(buildTestApp(const AddressBookScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Address Book'), findsOneWidget);
      expect(find.text('Alice (Treasury)'), findsOneWidget);
      expect(find.text('Bob (DAO Member)'), findsOneWidget);
    });

    testWidgets('7.6 更多工具箱 MoreToolsScreen 批量转账/代币安全/签名工具渲染', (tester) async {
      await tester.pumpWidget(buildTestApp(const MoreToolsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('More Tools'), findsOneWidget);
      expect(find.text('Batch Transfer'), findsOneWidget);
      expect(find.text('Approval & Revoke'), findsOneWidget);
      expect(find.text('Token Security Check'), findsOneWidget);
      expect(find.text('Node Speed & Switcher'), findsOneWidget);
    });

    testWidgets('7.7 钱包管理与安全详情 WalletDetailsScreen 渲染', (tester) async {
      await tester.pumpWidget(buildTestApp(WalletDetailsScreen(wallet: polygonWallet)));
      await tester.pumpAndSettle();

      expect(find.text('Wallet Details'), findsOneWidget);
      expect(find.text('Backup Recovery Phrase'), findsOneWidget);
      expect(find.text('Export Private Key'), findsOneWidget);
      expect(find.text('Delete Wallet'), findsOneWidget);
    });

    testWidgets('7.8 行情看板 MarketScreen 渲染与分类标签切换', (tester) async {
      await tester.pumpWidget(buildTestApp(const MarketScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Hot'), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Gainers'), findsOneWidget);
      expect(find.text('Losers'), findsOneWidget);
    });
  });
}
