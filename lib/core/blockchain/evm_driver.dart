import 'package:http/http.dart' as http;
import '../../domain/models/network.dart';
import '../../services/onchain_transaction_service.dart';
import 'blockchain_driver.dart';

/// 工业级标准 EVM 驱动实现 (EVM Blockchain Driver)
/// 适用于 Polygon (PoS), Ethereum, Arbitrum, BSC, Optimism, Base 等所有 EIP-155 标准 EVM 链。
class EVMDriver implements IBlockchainDriver {
  final IOnChainTransactionService _onChainService;

  EVMDriver({IOnChainTransactionService? onChainService})
      : _onChainService = onChainService ?? OnChainTransactionService();

  @override
  NetworkType get supportedType => NetworkType.evm;

  @override
  Future<double> getBalance({
    required Network network,
    required String address,
    http.Client? client,
  }) async {
    final clientToUse = client ?? http.Client();
    try {
      final res = await clientToUse.post(
        Uri.parse(network.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{"jsonrpc":"2.0","method":"eth_getBalance","params":["$address", "latest"],"id":1}',
      );
      if (res.statusCode == 200) {
        final data = res.body;
        final hexBalMatch = RegExp(r'"result":"(0x[0-9a-fA-F]+)"').firstMatch(data);
        if (hexBalMatch != null) {
          final hexVal = hexBalMatch.group(1)!.substring(2);
          final wei = BigInt.tryParse(hexVal, radix: 16) ?? BigInt.zero;
          return wei / BigInt.from(10).pow(18);
        }
      }
    } catch (_) {} finally {
      if (client == null) clientToUse.close();
    }
    return 0.0;
  }

  @override
  Future<double> getTokenBalance({
    required Network network,
    required String tokenContractAddress,
    required String walletAddress,
    int decimals = 18,
    http.Client? client,
  }) async {
    final clientToUse = client ?? http.Client();
    try {
      final cleanAddr = walletAddress.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
      final data = '0x70a08231$cleanAddr';
      final res = await clientToUse.post(
        Uri.parse(network.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"$tokenContractAddress","data":"$data"}, "latest"],"id":1}',
      );
      if (res.statusCode == 200) {
        final hexBalMatch = RegExp(r'"result":"(0x[0-9a-fA-F]+)"').firstMatch(res.body);
        if (hexBalMatch != null) {
          final hexVal = hexBalMatch.group(1)!.substring(2);
          final raw = BigInt.tryParse(hexVal, radix: 16) ?? BigInt.zero;
          return raw / BigInt.from(10).pow(decimals);
        }
      }
    } catch (_) {} finally {
      if (client == null) clientToUse.close();
    }
    return 0.0;
  }

  @override
  Future<int> getNonce({
    required Network network,
    required String address,
    http.Client? client,
  }) {
    return _onChainService.getNonce(network: network, address: address, client: client);
  }

  @override
  Future<BigInt> getGasPrice({
    required Network network,
    http.Client? client,
  }) {
    return _onChainService.getGasPrice(network: network, client: client);
  }

  @override
  Future<OnChainTxResult> sendNativeTransfer({
    required Network network,
    required String privateKeyHex,
    required String toAddress,
    required double amount,
    int? customNonce,
    BigInt? customGasPrice,
    http.Client? client,
  }) {
    return _onChainService.sendNativeTransfer(
      network: network,
      privateKeyHex: privateKeyHex,
      toAddress: toAddress,
      amount: amount,
      client: client,
    );
  }

  @override
  Future<OnChainTxResult> sendTokenTransfer({
    required Network network,
    required String privateKeyHex,
    required String tokenContractAddress,
    required String toAddress,
    required double amount,
    int decimals = 18,
    int? customNonce,
    BigInt? customGasPrice,
    http.Client? client,
  }) {
    return _onChainService.sendErc20Transfer(
      network: network,
      privateKeyHex: privateKeyHex,
      tokenContractAddress: tokenContractAddress,
      toAddress: toAddress,
      amount: amount,
      decimals: decimals,
      client: client,
    );
  }

  @override
  String getExplorerTxUrl(Network network, String txHash) {
    return _onChainService.getExplorerTxUrl(network, txHash);
  }
}
