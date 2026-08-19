import '../domain/models/network.dart';
import '../services/network_service.dart';
import '../storage/local_storage_service.dart';

abstract class INetworkRepository {
  List<Network> getAllNetworks();
  List<Network> searchNetworks(String query);
  Network? getNetworkById(String id);
  Future<Network> getSelectedNetwork();
  Future<void> setSelectedNetwork(String networkId);
}

class NetworkRepository implements INetworkRepository {
  final INetworkService _networkService;
  final ILocalStorageService _localStorageService;

  NetworkRepository({
    INetworkService? networkService,
    required ILocalStorageService localStorageService,
  })  : _networkService = networkService ?? NetworkService(),
        _localStorageService = localStorageService;

  @override
  List<Network> getAllNetworks() => _networkService.getSupportedNetworks();

  @override
  List<Network> searchNetworks(String query) => _networkService.searchNetworks(query);

  @override
  Network? getNetworkById(String id) => _networkService.getNetworkById(id);

  @override
  Future<Network> getSelectedNetwork() async {
    final savedId = await _localStorageService.getSelectedNetworkId();
    if (savedId != null) {
      final found = getNetworkById(savedId);
      if (found != null) return found;
    }
    return _networkService.getDefaultNetwork();
  }

  @override
  Future<void> setSelectedNetwork(String networkId) async {
    await _localStorageService.setSelectedNetworkId(networkId);
  }
}
