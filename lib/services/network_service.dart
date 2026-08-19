import '../core/config/app_config.dart';
import '../domain/models/network.dart';

abstract class INetworkService {
  List<Network> getSupportedNetworks();
  Network? getNetworkById(String id);
  Network getDefaultNetwork();
  List<Network> searchNetworks(String query);
}

class NetworkService implements INetworkService {
  static final List<Network> _defaultNetworks = [
    Network(
      id: 'polygon',
      name: 'Polygon',
      symbol: 'POL',
      chainId: 137,
      rpcUrl: AppConfig.alchemyPolygonRpc,
      blockExplorerUrl: AppConfig.polygonScanUrl,
      type: NetworkType.evm,
      defaultNamePrefix: 'POL',
    ),
    Network(
      id: 'bnb',
      name: 'BNB Chain',
      symbol: 'BNB',
      chainId: 56,
      rpcUrl: 'https://bsc-rpc.publicnode.com',
      blockExplorerUrl: AppConfig.bscScanUrl,
      type: NetworkType.evm,
      defaultNamePrefix: 'BNB',
    ),
    Network(
      id: 'ethereum',
      name: 'Ethereum',
      symbol: 'ETH',
      chainId: 1,
      rpcUrl: AppConfig.alchemyEthRpc,
      blockExplorerUrl: AppConfig.etherScanUrl,
      type: NetworkType.evm,
      defaultNamePrefix: 'ETH',
    ),
    Network(
      id: 'base',
      name: 'Base',
      symbol: 'ETH',
      chainId: 8453,
      rpcUrl: AppConfig.alchemyBaseRpc,
      blockExplorerUrl: AppConfig.baseScanUrl,
      type: NetworkType.evm,
      defaultNamePrefix: 'BASE',
    ),
    Network(
      id: 'arbitrum',
      name: 'Arbitrum One',
      symbol: 'ETH',
      chainId: 42161,
      rpcUrl: 'https://arbitrum-one-rpc.publicnode.com',
      blockExplorerUrl: AppConfig.arbiScanUrl,
      type: NetworkType.evm,
      defaultNamePrefix: 'ARB',
    ),
    Network(
      id: 'solana',
      name: 'Solana',
      symbol: 'SOL',
      chainId: 101,
      rpcUrl: AppConfig.alchemySolanaRpc,
      blockExplorerUrl: AppConfig.solScanUrl,
      type: NetworkType.solana,
      defaultNamePrefix: 'SOL',
    ),
    Network(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      chainId: 0,
      rpcUrl: AppConfig.btcScanUrl,
      blockExplorerUrl: AppConfig.btcScanUrl,
      type: NetworkType.bitcoin,
      defaultNamePrefix: 'BTC',
    ),
    Network(
      id: 'tron',
      name: 'Tron',
      symbol: 'TRX',
      chainId: 728126428,
      rpcUrl: 'https://api.trongrid.io',
      blockExplorerUrl: AppConfig.tronScanUrl,
      type: NetworkType.tron,
      defaultNamePrefix: 'TRX',
    ),
  ];

  @override
  List<Network> getSupportedNetworks() => List.unmodifiable(_defaultNetworks);

  @override
  Network? getNetworkById(String id) {
    try {
      return _defaultNetworks.firstWhere((n) => n.id.toLowerCase() == id.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Network getDefaultNetwork() => _defaultNetworks.first; // Polygon

  @override
  List<Network> searchNetworks(String query) {
    if (query.trim().isEmpty) return getSupportedNetworks();
    final lower = query.toLowerCase().trim();
    return _defaultNetworks.where((n) {
      return n.name.toLowerCase().contains(lower) ||
          n.symbol.toLowerCase().contains(lower) ||
          n.id.toLowerCase().contains(lower);
    }).toList();
  }
}
