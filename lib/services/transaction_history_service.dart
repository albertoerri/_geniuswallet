import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/network.dart';
import '../domain/models/transaction_record.dart';

abstract class ITransactionHistoryService {
  Future<List<TransactionRecord>> fetchTransactionHistory({
    required Network network,
    required String walletAddress,
    int page = 1,
    int offset = 20,
    http.Client? client,
  });

  void recordLocalTransaction(TransactionRecord record);

  List<TransactionRecord> getLocalHistory({required String walletAddress, String? networkId});
}

class TransactionHistoryService implements ITransactionHistoryService {
  final List<TransactionRecord> _localCache = [];

  @override
  void recordLocalTransaction(TransactionRecord record) {
    _localCache.removeWhere((r) => r.txHash.toLowerCase() == record.txHash.toLowerCase());
    _localCache.insert(0, record);
  }

  @override
  List<TransactionRecord> getLocalHistory({required String walletAddress, String? networkId}) {
    return _localCache.where((r) {
      final addrMatch = r.fromAddress.toLowerCase() == walletAddress.toLowerCase() ||
          r.toAddress.toLowerCase() == walletAddress.toLowerCase();
      final netMatch = networkId == null || r.networkId.toLowerCase() == networkId.toLowerCase();
      return addrMatch && netMatch;
    }).toList();
  }

  @override
  Future<List<TransactionRecord>> fetchTransactionHistory({
    required Network network,
    required String walletAddress,
    int page = 1,
    int offset = 20,
    http.Client? client,
  }) async {
    final clientToUse = client ?? http.Client();
    final records = <TransactionRecord>[];

    try {
      // 1. PolygonScan Public Explorer API (EVM Standard txlist)
      final apiUrl = Uri.parse(
        'https://api.polygonscan.com/api?module=account&action=txlist&address=$walletAddress&startblock=0&endblock=99999999&page=$page&offset=$offset&sort=desc',
      );

      final res = await clientToUse.get(apiUrl).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == '1' && data['result'] is List) {
          final txList = data['result'] as List;
          for (final item in txList) {
            final from = item['from']?.toString() ?? '';
            final to = item['to']?.toString() ?? '';
            final valWei = BigInt.tryParse(item['value']?.toString() ?? '0') ?? BigInt.zero;
            final amount = valWei / BigInt.from(10).pow(18);
            final timeSec = int.tryParse(item['timeStamp']?.toString() ?? '0') ?? 0;
            final isErr = item['isError'] == '1';

            records.add(
              TransactionRecord(
                txHash: item['hash'] ?? '',
                fromAddress: from,
                toAddress: to,
                amount: amount,
                symbol: network.symbol,
                timestamp: timeSec > 0
                    ? DateTime.fromMillisecondsSinceEpoch(timeSec * 1000)
                    : DateTime.now(),
                status: isErr ? TransactionStatus.failed : TransactionStatus.success,
                type: from.toLowerCase() == walletAddress.toLowerCase()
                    ? TransactionType.send
                    : TransactionType.receive,
                networkId: network.id,
                explorerUrl: '${network.blockExplorerUrl}/tx/${item['hash']}',
              ),
            );
          }
        }
      }
    } catch (_) {} finally {
      if (client == null) clientToUse.close();
    }

    // 合并本地最新广播但可能未被区块浏览器及时收录的记录
    final local = getLocalHistory(walletAddress: walletAddress, networkId: network.id);
    for (final loc in local) {
      if (!records.any((r) => r.txHash.toLowerCase() == loc.txHash.toLowerCase())) {
        records.insert(0, loc);
      }
    }

    return records;
  }
}
