import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:geniuswallet/core/config/app_config.dart';
import 'package:geniuswallet/domain/models/network.dart';
import 'package:geniuswallet/domain/models/token.dart';
import 'package:geniuswallet/presentation/controllers/environment_controller.dart';
import 'package:geniuswallet/services/crypto_key_service.dart';
import 'package:geniuswallet/services/environment_service.dart';
import 'package:geniuswallet/services/onchain_transaction_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvironmentService & Controller Tests', () {
    test('Defaults to Live Mainnet environment', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final envService = EnvironmentService(prefs: prefs);
      final envController = EnvironmentController(service: envService);

      expect(envController.isLive, isTrue);
      expect(envController.mode, equals(EnvironmentMode.live));

      await envController.setMode(EnvironmentMode.simulation);
      expect(envController.isLive, isFalse);
      expect(envController.mode, equals(EnvironmentMode.simulation));
      expect(prefs.getString('app_environment_mode'), equals('simulation'));

      await envController.toggleMode();
      expect(envController.isLive, isTrue);
      expect(prefs.getString('app_environment_mode'), equals('live'));
    });
  });

  group('OnChainTransactionService Tests', () {
    late OnChainTransactionService onChainService;
    late Network polygonNetwork;
    const testPrivateKey = '4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f3608ba';
    const testRecipient = '0x90F79bf6EB2c4f870365E785982E1f101E93b906';

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
      onChainService = OnChainTransactionService();
    });

    test('Generates correct PolygonScan transaction URL', () {
      const txHash = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final url = onChainService.getExplorerTxUrl(polygonNetwork, txHash);
      expect(url, equals('https://polygonscan.com/tx/$txHash'));
    });

    test('Queries Nonce and Gas Price successfully via RPC', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x5'}), 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x6fc23ac00'}), 200); // 30 Gwei
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final nonce = await onChainService.getNonce(
        network: polygonNetwork,
        address: '0x2c7536E3605D9C16a7a3D7b1898e529396a65c23',
        client: mockClient,
      );
      expect(nonce, equals(5));

      final gasPrice = await onChainService.getGasPrice(
        network: polygonNetwork,
        client: mockClient,
      );
      expect(gasPrice, equals(BigInt.from(30000000000)));
    });

    test('Signs and broadcasts Native POL transfer on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x0'}), 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x77359400'}), 200);
        } else if (method == 'eth_sendRawTransaction') {
          final params = body['params'] as List;
          expect(params.first.toString().startsWith('0x'), isTrue);
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': '0x9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
            }),
            200,
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final result = await onChainService.sendNativeTransfer(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        toAddress: testRecipient,
        amount: 1.5,
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, equals('0x9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b'));
      expect(result.explorerUrl, contains('https://polygonscan.com/tx/0x9a8b7c'));
      expect(result.nonce, equals(0));
    });

    test('Signs and broadcasts ERC-20 (USDT / USDC) transfer on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x2'}), 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x77359400'}), 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': '0x11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff',
            }),
            200,
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final result = await onChainService.sendErc20Transfer(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        tokenContractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F', // USDT Polygon
        toAddress: testRecipient,
        amount: 50.0,
        decimals: 6,
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, equals('0x11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff'));
      expect(result.explorerUrl, contains('https://polygonscan.com/tx/0x112233'));
      expect(result.nonce, equals(2));
    });

    test('Signs and broadcasts real DEX Swap (POL -> USDT) on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x3'}), 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x77359400'}), 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': '0x778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566',
            }),
            200,
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

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

      final result = await onChainService.sendSwapTransaction(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        fromToken: fromToken,
        toToken: toToken,
        fromAmount: 10.0,
        minToAmount: 4.1,
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, equals('0x778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566'));
      expect(result.explorerUrl, contains('https://polygonscan.com/tx/0x778899'));
    });

    test('Signs and broadcasts ERC-20 approval revocation on Polygon Mainnet', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x4'}), 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x77359400'}), 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'result': '0xaa11223344556677889900aabbccddeeffaa11223344556677889900aabbccddee',
            }),
            200,
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final result = await onChainService.revokeApproval(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        tokenContractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        spenderAddress: '0xE592427A0AEce92De3Edee1F18E0157C05861564',
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.txHash, equals('0xaa11223344556677889900aabbccddeeffaa11223344556677889900aabbccddee'));
    });

    test('Queries on-chain smart contract bytecode via RPC', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getCode') {
          return http.Response(jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'result': '0x608060405234801561001057600080fd5b50610123806100206000396000f3',
          }), 200);
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final report = await onChainService.checkContractSecurityOnChain(
        network: polygonNetwork,
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        client: mockClient,
      );

      expect(report.isContract, isTrue);
      expect(report.bytecodeSize, greaterThan(0));
      expect(report.isHoneypotRisk, isFalse);
    });

    test('Handles RPC error gracefully', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'];
        if (method == 'eth_getTransactionCount') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x1'}), 200);
        } else if (method == 'eth_gasPrice') {
          return http.Response(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x77359400'}), 200);
        } else if (method == 'eth_sendRawTransaction') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'error': {'code': -32000, 'message': 'insufficient funds for gas * price + value'},
            }),
            200,
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final result = await onChainService.sendNativeTransfer(
        network: polygonNetwork,
        privateKeyHex: testPrivateKey,
        toAddress: testRecipient,
        amount: 100.0,
        client: mockClient,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('insufficient funds'));
    });
  });
}
