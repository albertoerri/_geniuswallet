import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/asset_controller.dart';
import 'presentation/controllers/network_controller.dart';
import 'presentation/controllers/wallet_controller.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'repositories/asset_repository.dart';
import 'repositories/network_repository.dart';
import 'repositories/wallet_repository.dart';
import 'services/asset_service.dart';
import 'services/crypto_key_service.dart';
import 'services/network_service.dart';
import 'services/wallet_service.dart';
import 'storage/local_storage_service.dart';
import 'storage/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Storage Layer
  final sharedPrefs = await SharedPreferences.getInstance();
  final localStorageService = LocalStorageService(sharedPrefs);
  final secureStorageService = SecureStorageService();

  // 2. Initialize Service Layer
  final cryptoKeyService = CryptoKeyService();
  final networkService = NetworkService();
  final walletService = WalletService(cryptoService: cryptoKeyService);
  final assetService = AssetService();

  // 3. Initialize Repository Layer
  final networkRepository = NetworkRepository(
    networkService: networkService,
    localStorageService: localStorageService,
  );
  final walletRepository = WalletRepository(
    localStorageService: localStorageService,
    secureStorageService: secureStorageService,
  );
  final assetRepository = AssetRepository(assetService: assetService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NetworkController(networkRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletController(
            repository: walletRepository,
            walletService: walletService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AssetController(repository: assetRepository),
        ),
      ],
      child: const GeniusWalletApp(),
    ),
  );
}

class GeniusWalletApp extends StatelessWidget {
  const GeniusWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genius Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
