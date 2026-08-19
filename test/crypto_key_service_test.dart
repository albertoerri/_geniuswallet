import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/services/crypto_key_service.dart';

void main() {
  group('CryptoKeyService', () {
    late CryptoKeyService cryptoService;

    setUp(() {
      cryptoService = CryptoKeyService();
    });

    test('should validate and derive valid BIP39 12-word mnemonic', () {
      // Known test vector
      const mnemonic = 'test test test test test test test test test test test junk';
      expect(cryptoService.validateMnemonic(mnemonic), isTrue);

      final result = cryptoService.deriveFromMnemonic(mnemonic);
      expect(result.address.startsWith('0x'), isTrue);
      expect(result.address.length, equals(42));
      expect(result.privateKeyHex.length, equals(64));
      expect(result.mnemonic, equals(mnemonic));
    });

    test('should reject invalid mnemonic', () {
      const invalidMnemonic = 'not a valid mnemonic phrase at all';
      expect(cryptoService.validateMnemonic(invalidMnemonic), isFalse);
      expect(() => cryptoService.deriveFromMnemonic(invalidMnemonic), throwsFormatException);
    });

    test('should validate and derive valid 64-hex private key', () {
      const privateKey = '4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f36088a';
      expect(cryptoService.validatePrivateKey(privateKey), isTrue);

      final result = cryptoService.deriveFromPrivateKey(privateKey);
      expect(result.address.startsWith('0x'), isTrue);
      expect(result.address.length, equals(42));
      expect(result.privateKeyHex, equals(privateKey));
    });

    test('should validate private key with 0x prefix', () {
      const privateKeyWith0x = '0x4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f36088a';
      expect(cryptoService.validatePrivateKey(privateKeyWith0x), isTrue);

      final result = cryptoService.deriveFromPrivateKey(privateKeyWith0x);
      expect(result.address.startsWith('0x'), isTrue);
    });

    test('should reject invalid private key', () {
      const invalidPrivateKey = '12345nonhexkey';
      expect(cryptoService.validatePrivateKey(invalidPrivateKey), isFalse);
      expect(() => cryptoService.deriveFromPrivateKey(invalidPrivateKey), throwsFormatException);
    });
  });
}
