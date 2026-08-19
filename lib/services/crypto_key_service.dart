import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import '../core/utils/formatters.dart';

class DerivedKeyResult {
  final String address;
  final String privateKeyHex;
  final String? mnemonic;

  DerivedKeyResult({
    required this.address,
    required this.privateKeyHex,
    this.mnemonic,
  });
}

abstract class ICryptoKeyService {
  bool validateMnemonic(String mnemonic);
  bool validatePrivateKey(String privateKey);
  DerivedKeyResult deriveFromMnemonic(String mnemonic, {String derivationPath = "m/44'/60'/0'/0/0"});
  DerivedKeyResult deriveFromPrivateKey(String privateKey);
  String generateMnemonic();
}

class CryptoKeyService implements ICryptoKeyService {
  @override
  bool validateMnemonic(String mnemonic) {
    final cleaned = Formatters.cleanMnemonic(mnemonic);
    if (cleaned.isEmpty) return false;
    final words = cleaned.split(' ');
    if (words.length != 12 && words.length != 24) return false;
    return bip39.validateMnemonic(cleaned);
  }

  @override
  bool validatePrivateKey(String privateKey) {
    final cleaned = Formatters.cleanPrivateKey(privateKey);
    if (cleaned.length != 64) return false;
    try {
      HEX.decode(cleaned);
      EthPrivateKey.fromHex(cleaned);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  DerivedKeyResult deriveFromMnemonic(
    String mnemonic, {
    String derivationPath = "m/44'/60'/0'/0/0",
  }) {
    final cleaned = Formatters.cleanMnemonic(mnemonic);
    if (!validateMnemonic(cleaned)) {
      throw const FormatException('Invalid BIP39 recovery phrase');
    }

    final Uint8List seed = bip39.mnemonicToSeed(cleaned);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(derivationPath);

    if (child.privateKey == null) {
      throw const FormatException('Failed to derive private key from seed');
    }

    final privateKeyHex = HEX.encode(child.privateKey!);
    final ethKey = EthPrivateKey.fromHex(privateKeyHex);
    final address = ethKey.address.hexEip55;

    return DerivedKeyResult(
      address: address,
      privateKeyHex: privateKeyHex,
      mnemonic: cleaned,
    );
  }

  @override
  DerivedKeyResult deriveFromPrivateKey(String privateKey) {
    final cleaned = Formatters.cleanPrivateKey(privateKey);
    if (!validatePrivateKey(cleaned)) {
      throw const FormatException('Invalid 64-character hex private key');
    }

    final ethKey = EthPrivateKey.fromHex(cleaned);
    final address = ethKey.address.hexEip55;

    return DerivedKeyResult(
      address: address,
      privateKeyHex: cleaned,
    );
  }

  @override
  String generateMnemonic() {
    return bip39.generateMnemonic();
  }
}
