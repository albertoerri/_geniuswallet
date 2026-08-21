import 'package:uuid/uuid.dart';
import '../domain/models/wallet.dart';
import 'crypto_key_service.dart';

abstract class IWalletService {
  DerivedKeyResult processImportInput({
    required WalletImportType importType,
    required String secretInput,
    String? derivationPath,
    String? password,
  });

  Wallet createWalletEntity({
    required String name,
    required String address,
    required String networkId,
    required WalletImportType importType,
  });
}

class WalletService implements IWalletService {
  final ICryptoKeyService _cryptoService;
  final Uuid _uuid;

  WalletService({
    ICryptoKeyService? cryptoService,
    Uuid? uuid,
  })  : _cryptoService = cryptoService ?? CryptoKeyService(),
        _uuid = uuid ?? const Uuid();

  @override
  DerivedKeyResult processImportInput({
    required WalletImportType importType,
    required String secretInput,
    String? derivationPath,
    String? password,
  }) {
    if (importType == WalletImportType.recoveryPhrase) {
      return _cryptoService.deriveFromMnemonic(
        secretInput,
        derivationPath: derivationPath ?? "m/44'/60'/0'/0/0",
      );
    } else if (importType == WalletImportType.privateKey) {
      return _cryptoService.deriveFromPrivateKey(secretInput);
    } else if (importType == WalletImportType.keystore) {
      return _cryptoService.deriveFromKeystore(secretInput, password ?? '');
    } else if (importType == WalletImportType.watchWallet) {
      return _cryptoService.deriveFromAddress(secretInput);
    } else if (importType == WalletImportType.coldWallet || importType == WalletImportType.syncWallet) {
      if (secretInput.startsWith('0x') && secretInput.length == 42) {
        return _cryptoService.deriveFromAddress(secretInput);
      } else if (secretInput.length == 64 || (secretInput.startsWith('0x') && secretInput.length == 66)) {
        return _cryptoService.deriveFromPrivateKey(secretInput);
      } else {
        return _cryptoService.deriveFromMnemonic(
          secretInput,
          derivationPath: derivationPath ?? "m/44'/60'/0'/0/0",
        );
      }
    } else {
      throw UnsupportedError('Unsupported import type: $importType');
    }
  }

  @override
  Wallet createWalletEntity({
    required String name,
    required String address,
    required String networkId,
    required WalletImportType importType,
  }) {
    return Wallet(
      id: _uuid.v4(),
      name: name.trim(),
      address: address,
      networkId: networkId,
      importType: importType,
      createdAt: DateTime.now(),
      isBackedUp: true,
    );
  }
}
