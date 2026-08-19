import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ISecureStorageService {
  Future<void> writeSecret({required String key, required String value});
  Future<String?> readSecret({required String key});
  Future<void> deleteSecret({required String key});
  Future<void> deleteAllSecrets();
}

class SecureStorageService implements ISecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static String _walletSecretKey(String walletId) => 'wallet_secret_$walletId';

  @override
  Future<void> writeSecret({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> readSecret({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> deleteSecret({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAllSecrets() async {
    await _storage.deleteAll();
  }

  // Convenience methods for wallet secrets
  Future<void> saveWalletSecret(String walletId, String secret) async {
    await writeSecret(key: _walletSecretKey(walletId), value: secret);
  }

  Future<String?> getWalletSecret(String walletId) async {
    return await readSecret(key: _walletSecretKey(walletId));
  }

  Future<void> deleteWalletSecret(String walletId) async {
    await deleteSecret(key: _walletSecretKey(walletId));
  }
}
