import 'package:flutter/material.dart';
import '../../domain/models/network.dart';
import '../../repositories/network_repository.dart';

class NetworkController extends ChangeNotifier {
  final INetworkRepository _repository;

  List<Network> _allNetworks = [];
  List<Network> _filteredNetworks = [];
  Network? _selectedNetwork;
  String _searchQuery = '';
  bool _isLoading = false;

  NetworkController(this._repository) {
    loadNetworks();
  }

  List<Network> get networks => _filteredNetworks;
  List<Network> get allNetworks => _allNetworks;
  Network? get selectedNetwork => _selectedNetwork;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> loadNetworks() async {
    _isLoading = true;
    notifyListeners();

    _allNetworks = _repository.getAllNetworks();
    _filteredNetworks = _allNetworks;
    _selectedNetwork = await _repository.getSelectedNetwork();

    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _filteredNetworks = _allNetworks;
    } else {
      _filteredNetworks = _repository.searchNetworks(query);
    }
    notifyListeners();
  }

  Future<void> selectNetwork(Network network) async {
    _selectedNetwork = network;
    await _repository.setSelectedNetwork(network.id);
    notifyListeners();
  }
}
