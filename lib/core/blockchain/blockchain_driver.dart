import 'package:http/http.dart' as http;
import '../../domain/models/network.dart';
import '../../domain/models/token.dart';
import '../../services/onchain_transaction_service.dart';

/// 统一多链驱动标准接口 (Universal Blockchain Driver Interface)
/// 所有公链（EVM / Solana / Bitcoin / Tron / Cosmos 等）均实现该接口，实现零侵入式插拔扩展。
abstract class IBlockchainDriver {
  NetworkType get supportedType;

  /// 查询主币真实链上余额
  Future<double> getBalance({
    required Network network,
    required String address,
    http.Client? client,
  });

  /// 查询代币真实链上余额 (ERC-20, SPL, TRC-20 等)
  Future<double> getTokenBalance({
    required Network network,
    required String tokenContractAddress,
    required String walletAddress,
    int decimals = 18,
    http.Client? client,
  });

  /// 获取当前待处理 Nonce / 交易序号
  Future<int> getNonce({
    required Network network,
    required String address,
    http.Client? client,
  });

  /// 获取当前网络 Gas / 矿工费基准
  Future<BigInt> getGasPrice({
    required Network network,
    http.Client? client,
  });

  /// 发送原生主币转账 (离线签名并广播)
  Future<OnChainTxResult> sendNativeTransfer({
    required Network network,
    required String privateKeyHex,
    required String toAddress,
    required double amount,
    int? customNonce,
    BigInt? customGasPrice,
    http.Client? client,
  });

  /// 发送代币合约转账 (离线签名并广播)
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
  });

  /// 获取对应区块浏览器交易详情 URL
  String getExplorerTxUrl(Network network, String txHash);
}
