import 'package:flutter/material.dart';
import '../../domain/models/wallet.dart';
import '../../repositories/wallet_repository.dart';
import '../../services/wallet_service.dart';

class WalletController extends ChangeNotifier {
  final IWalletRepository _repository;
  final IWalletService _walletService;

  List<Wallet> _wallets = [];
  Wallet? _activeWallet;
  bool _isLoading = true;
  String? _errorMessage;

  WalletController({
    required IWalletRepository repository,
    IWalletService? walletService,
  })  : _repository = repository,
        _walletService = walletService ?? WalletService() {
    loadWallets();
  }

  List<Wallet> get wallets => _wallets;
  Wallet? get activeWallet => _activeWallet;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasWallets => _wallets.isNotEmpty;

  Future<void> loadWallets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallets = await _repository.getWallets();
      _activeWallet = await _repository.getActiveWallet();
    } catch (e) {
      _errorMessage = 'Failed to load wallets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getDefaultWalletName(String networkPrefix, String networkId) async {
    final count = await _repository.getWalletCountForNetwork(networkId);
    return '$networkPrefix-${count + 1}';
  }

  Future<bool> createWallet({
    required String name,
    required String mnemonic,
    required String networkId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final derivedResult = _walletService.processImportInput(
        importType: WalletImportType.recoveryPhrase,
        secretInput: mnemonic,
      );

      final newWallet = _walletService.createWalletEntity(
        name: name.trim().isEmpty ? '$networkId-Wallet' : name.trim(),
        address: derivedResult.address,
        networkId: networkId,
        importType: WalletImportType.generated,
      );

      await _repository.saveWallet(
        wallet: newWallet,
        secret: mnemonic.trim(),
      );

      _wallets = await _repository.getWallets();
      _activeWallet = newWallet;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('FormatException: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> importWallet({
    required String name,
    required String secret,
    required WalletImportType importType,
    required String networkId,
    String? derivationPath,
    String? password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Process cryptographic derivation
      final derivedResult = _walletService.processImportInput(
        importType: importType,
        secretInput: secret,
        derivationPath: derivationPath,
        password: password,
      );

      // 2. Create wallet entity
      final newWallet = _walletService.createWalletEntity(
        name: name.trim().isEmpty ? '$networkId-Wallet' : name.trim(),
        address: derivedResult.address,
        networkId: networkId,
        importType: importType,
      );

      // 3. Save to repository (Secure storage for secret + LocalStorage for metadata)
      await _repository.saveWallet(
        wallet: newWallet,
        secret: secret.trim(),
      );

      // 4. Refresh wallet list
      _wallets = await _repository.getWallets();
      _activeWallet = newWallet;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('FormatException: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createIdentityWallet({
    required String name,
    required String mnemonic,
    List<String> networkIds = const ['polygon', 'binancesmartchain', 'ethereum', 'base', 'arbitrum', 'optimism'],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final derivedResult = _walletService.processImportInput(
        importType: WalletImportType.recoveryPhrase,
        secretInput: mnemonic,
      );

      Wallet? firstCreated;
      for (final netId in networkIds) {
        final walletName = '$name-${netId.toUpperCase().substring(0, netId.length > 3 ? 3 : netId.length)}';
        final newWallet = _walletService.createWalletEntity(
          name: walletName,
          address: derivedResult.address,
          networkId: netId,
          importType: WalletImportType.recoveryPhrase,
        );

        await _repository.saveWallet(
          wallet: newWallet,
          secret: mnemonic.trim(),
        );

        firstCreated ??= newWallet;
      }

      _wallets = await _repository.getWallets();
      if (firstCreated != null) {
        _activeWallet = firstCreated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('FormatException: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMultiSigWallet({
    required String name,
    required String networkId,
    required int threshold,
    required List<String> owners,
    String? contractAddress,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // If contract address not provided, generate a deterministic multi-sig safe address
      final hashHex = (name + networkId + threshold.toString() + owners.join()).hashCode.abs().toRadixString(16);
      final safeAddress = contractAddress?.trim().isNotEmpty == true
          ? contractAddress!.trim()
          : '0x${hashHex.padLeft(40, 'a').substring(0, 40)}';

      final derivedResult = _walletService.processImportInput(
        importType: WalletImportType.watchWallet,
        secretInput: safeAddress,
      );

      final newWallet = _walletService.createWalletEntity(
        name: name.trim().isEmpty ? 'MultiSig-$threshold/${owners.length}' : name.trim(),
        address: derivedResult.address,
        networkId: networkId,
        importType: WalletImportType.watchWallet,
      );

      await _repository.saveWallet(
        wallet: newWallet,
        secret: safeAddress,
      );

      _wallets = await _repository.getWallets();
      _activeWallet = newWallet;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('FormatException: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> switchActiveWallet(String walletId) async {
    await _repository.setActiveWallet(walletId);
    _activeWallet = _wallets.firstWhere((w) => w.id == walletId, orElse: () => _wallets.first);
    notifyListeners();
  }

  Future<void> renameWallet(String walletId, String newName) async {
    await _repository.renameWallet(walletId, newName);
    _wallets = await _repository.getWallets();
    if (_activeWallet?.id == walletId) {
      _activeWallet = _wallets.firstWhere((w) => w.id == walletId, orElse: () => _wallets.first);
    }
    notifyListeners();
  }

  Future<String?> getWalletSecret(String walletId) async {
    return await _repository.getWalletSecret(walletId);
  }

  Future<void> deleteWallet(String walletId) async {
    await _repository.deleteWallet(walletId);
    await loadWallets();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
