import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geniuswallet/domain/models/wallet.dart';
import 'package:geniuswallet/storage/local_storage_service.dart';
import 'package:geniuswallet/storage/secure_storage_service.dart';
import 'package:geniuswallet/repositories/wallet_repository.dart';

class MockSecureStorageService extends SecureStorageService {
  final Map<String, String> _secrets = {};

  @override
  Future<void> writeSecret({required String key, required String value}) async {
    _secrets[key] = value;
  }

  @override
  Future<String?> readSecret({required String key}) async {
    return _secrets[key];
  }

  @override
  Future<void> deleteSecret({required String key}) async {
    _secrets.remove(key);
  }
}

void main() {
  group('WalletRepository', () {
    late LocalStorageService localStorage;
    late MockSecureStorageService mockSecureStorage;
    late WalletRepository walletRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      localStorage = LocalStorageService(prefs);
      mockSecureStorage = MockSecureStorageService();
      walletRepo = WalletRepository(
        localStorageService: localStorage,
        secureStorageService: mockSecureStorage,
      );
    });

    test('should save, retrieve, and switch active wallet', () async {
      expect(await walletRepo.getWallets(), isEmpty);
      expect(await walletRepo.getActiveWallet(), isNull);

      final wallet1 = Wallet(
        id: 'w1',
        name: 'POL-1',
        address: '0x1234567890123456789012345678901234567890',
        networkId: 'polygon',
        importType: WalletImportType.recoveryPhrase,
        createdAt: DateTime.now(),
      );

      await walletRepo.saveWallet(wallet: wallet1, secret: 'phrase phrase phrase ...');

      final wallets = await walletRepo.getWallets();
      expect(wallets.length, equals(1));
      expect(wallets.first.name, equals('POL-1'));

      final active = await walletRepo.getActiveWallet();
      expect(active?.id, equals('w1'));

      final secret = await walletRepo.getWalletSecret('w1');
      expect(secret, equals('phrase phrase phrase ...'));
    });

    test('should delete wallet and secret', () async {
      final wallet1 = Wallet(
        id: 'w1',
        name: 'POL-1',
        address: '0x1234567890123456789012345678901234567890',
        networkId: 'polygon',
        importType: WalletImportType.recoveryPhrase,
        createdAt: DateTime.now(),
      );

      await walletRepo.saveWallet(wallet: wallet1, secret: 'secret1');
      expect(await walletRepo.getWallets(), isNotEmpty);

      await walletRepo.deleteWallet('w1');
      expect(await walletRepo.getWallets(), isEmpty);
      expect(await walletRepo.getWalletSecret('w1'), isNull);
    });
  });
}
