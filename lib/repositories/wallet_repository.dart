import '../domain/models/wallet.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';

abstract class IWalletRepository {
  Future<List<Wallet>> getWallets();
  Future<Wallet?> getActiveWallet();
  Future<void> setActiveWallet(String walletId);
  Future<void> saveWallet({required Wallet wallet, required String secret});
  Future<String?> getWalletSecret(String walletId);
  Future<void> deleteWallet(String walletId);
  Future<void> renameWallet(String walletId, String newName);
  Future<int> getWalletCountForNetwork(String networkId);
}

class WalletRepository implements IWalletRepository {
  final ILocalStorageService _localStorageService;
  final SecureStorageService _secureStorageService;

  WalletRepository({
    required ILocalStorageService localStorageService,
    required SecureStorageService secureStorageService,
  })  : _localStorageService = localStorageService,
        _secureStorageService = secureStorageService;

  @override
  Future<List<Wallet>> getWallets() async {
    return await _localStorageService.getWallets();
  }

  @override
  Future<Wallet?> getActiveWallet() async {
    final activeId = await _localStorageService.getActiveWalletId();
    final wallets = await getWallets();
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
    await _localStorageService.setActiveWalletId(walletId);
  }

  @override
  Future<void> saveWallet({required Wallet wallet, required String secret}) async {
    // 1. Save sensitive secret in hardware-backed secure storage
    await _secureStorageService.saveWalletSecret(wallet.id, secret);

    // 2. Add or update wallet metadata in local storage
    final wallets = await _localStorageService.getWallets();
    final existingIndex = wallets.indexWhere((w) => w.id == wallet.id);

    if (existingIndex >= 0) {
      wallets[existingIndex] = wallet;
    } else {
      wallets.add(wallet);
    }

    await _localStorageService.saveWallets(wallets);

    // 3. Set as active wallet
    await _localStorageService.setActiveWalletId(wallet.id);
  }

  @override
  Future<String?> getWalletSecret(String walletId) async {
    return await _secureStorageService.getWalletSecret(walletId);
  }

  @override
  Future<void> renameWallet(String walletId, String newName) async {
    final wallets = await _localStorageService.getWallets();
    final index = wallets.indexWhere((w) => w.id == walletId);
    if (index >= 0) {
      wallets[index] = wallets[index].copyWith(name: newName);
      await _localStorageService.saveWallets(wallets);
    }
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    // 1. Delete secret
    await _secureStorageService.deleteWalletSecret(walletId);

    // 2. Remove from wallet list
    final wallets = await _localStorageService.getWallets();
    wallets.removeWhere((w) => w.id == walletId);
    await _localStorageService.saveWallets(wallets);

    // 3. Update active wallet if needed
    final activeId = await _localStorageService.getActiveWalletId();
    if (activeId == walletId) {
      if (wallets.isNotEmpty) {
        await _localStorageService.setActiveWalletId(wallets.first.id);
      } else {
        await _localStorageService.setActiveWalletId(null);
      }
    }
  }

  @override
  Future<int> getWalletCountForNetwork(String networkId) async {
    final wallets = await getWallets();
    return wallets.where((w) => w.networkId.toLowerCase() == networkId.toLowerCase()).length;
  }
}
