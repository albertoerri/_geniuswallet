import '../../domain/models/network.dart';
import 'blockchain_driver.dart';
import 'evm_driver.dart';

/// 区块链多链驱动注册表与分发中心 (Blockchain Driver Registry)
/// 单例管理各链 Driver 实例，外部代码只需传入 Network 即可自动路由到对应的链底层驱动。
class BlockchainDriverRegistry {
  static final BlockchainDriverRegistry _instance = BlockchainDriverRegistry._internal();
  factory BlockchainDriverRegistry() => _instance;
  BlockchainDriverRegistry._internal() {
    // 默认注册标准 EVM 驱动
    registerDriver(NetworkType.evm, EVMDriver());
  }

  final Map<NetworkType, IBlockchainDriver> _drivers = {};

  void registerDriver(NetworkType type, IBlockchainDriver driver) {
    _drivers[type] = driver;
  }

  IBlockchainDriver getDriver(NetworkType type) {
    final driver = _drivers[type];
    if (driver != null) {
      return driver;
    }
    // 默认回退至 EVM 驱动
    return _drivers[NetworkType.evm] ?? EVMDriver();
  }

  IBlockchainDriver forNetwork(Network network) {
    return getDriver(network.type);
  }
}
