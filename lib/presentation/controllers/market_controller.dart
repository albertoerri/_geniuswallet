import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/models/market_item.dart';
import '../../storage/local_storage_service.dart';

enum MarketTab {
  watchlist,
  hot,
  gainers,
  losers,
  newListings,
  ecosystem,
}

enum MarketSortField {
  none,
  name,
  price,
  change,
  volume,
}

enum MarketSortOrder {
  none,
  ascending,
  descending,
}

class MarketController extends ChangeNotifier {
  final LocalStorageService? _storageService;

  MarketTab _currentTab = MarketTab.hot;
  String _selectedEcosystem = 'all';
  String _searchQuery = '';
  MarketSortField _sortField = MarketSortField.none;
  MarketSortOrder _sortOrder = MarketSortOrder.none;
  bool _isLoading = false;
  Set<String> _favoriteIds = {'btc', 'eth', 'pol', 'sol'};

  // Global Market Stats
  final double totalMarketCap = 2680000000000;
  final double marketCapChange24h = 2.45;
  final double totalVolume24h = 89540000000;
  final double btcDominance = 56.4;
  final int gasGwei = 28;

  List<MarketItem> _allItems = [];

  MarketController([this._storageService]) {
    _initDefaults();
    _loadFavorites();
  }

  MarketTab get currentTab => _currentTab;
  String get selectedEcosystem => _selectedEcosystem;
  String get searchQuery => _searchQuery;
  MarketSortField get sortField => _sortField;
  MarketSortOrder get sortOrder => _sortOrder;
  bool get isLoading => _isLoading;

  void _initDefaults() {
    _allItems = [
      const MarketItem(
        id: 'btc',
        symbol: 'BTC',
        name: 'Bitcoin',
        priceUsd: 64280.50,
        change24h: 3.42,
        volume24h: 28450000000,
        marketCap: 1268000000000,
        high24h: 65100.0,
        low24h: 62800.0,
        category: 'Layer 1',
        networkId: 'bitcoin',
        rank: 1,
        sparkline: [62.8, 63.1, 62.9, 63.5, 64.0, 63.8, 64.2, 64.28],
      ),
      const MarketItem(
        id: 'eth',
        symbol: 'ETH',
        name: 'Ethereum',
        priceUsd: 3450.20,
        change24h: 4.15,
        volume24h: 15400000000,
        marketCap: 415000000000,
        high24h: 3520.0,
        low24h: 3310.0,
        category: 'Layer 1',
        networkId: 'ethereum',
        rank: 2,
        sparkline: [33.1, 33.4, 33.2, 33.9, 34.1, 34.0, 34.3, 34.5],
      ),
      const MarketItem(
        id: 'pol',
        symbol: 'POL',
        name: 'Polygon Ecosystem Token',
        priceUsd: 0.1262,
        change24h: 6.84,
        volume24h: 890000000,
        marketCap: 1250000000,
        high24h: 0.1310,
        low24h: 0.1180,
        category: 'Layer 2',
        networkId: 'polygon',
        contractAddress: '0x455e53CBB86018Ac2B8092DDcd39d8444aFFC3e6',
        rank: 3,
        sparkline: [0.118, 0.120, 0.119, 0.122, 0.124, 0.123, 0.125, 0.1262],
      ),
      const MarketItem(
        id: 'bnb',
        symbol: 'BNB',
        name: 'BNB Chain',
        priceUsd: 582.40,
        change24h: 1.82,
        volume24h: 1200000000,
        marketCap: 87500000000,
        high24h: 589.0,
        low24h: 571.0,
        category: 'Layer 1',
        networkId: 'bnb',
        rank: 4,
        sparkline: [57.1, 57.5, 57.3, 57.8, 58.0, 57.9, 58.1, 58.24],
      ),
      const MarketItem(
        id: 'sol',
        symbol: 'SOL',
        name: 'Solana',
        priceUsd: 148.60,
        change24h: 8.92,
        volume24h: 4200000000,
        marketCap: 69000000000,
        high24h: 152.0,
        low24h: 136.0,
        category: 'Layer 1',
        networkId: 'solana',
        rank: 5,
        sparkline: [13.6, 13.9, 14.1, 14.4, 14.2, 14.6, 14.7, 14.86],
      ),
      const MarketItem(
        id: 'usdt',
        symbol: 'USDT',
        name: 'Tether USD',
        priceUsd: 0.9998,
        change24h: 0.01,
        volume24h: 42000000000,
        marketCap: 118000000000,
        high24h: 1.0002,
        low24h: 0.9995,
        category: 'DeFi',
        networkId: 'polygon',
        contractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        rank: 6,
        sparkline: [0.999, 1.0, 0.999, 1.0, 0.999, 1.0, 0.999, 0.9998],
      ),
      const MarketItem(
        id: 'usdc',
        symbol: 'USDC',
        name: 'USD Coin',
        priceUsd: 0.9999,
        change24h: -0.01,
        volume24h: 8500000000,
        marketCap: 35000000000,
        high24h: 1.0001,
        low24h: 0.9998,
        category: 'DeFi',
        networkId: 'polygon',
        contractAddress: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359',
        rank: 7,
        sparkline: [1.0, 0.999, 1.0, 0.999, 1.0, 0.999, 1.0, 0.9999],
      ),
      const MarketItem(
        id: 'pepe',
        symbol: 'PEPE',
        name: 'Pepe',
        priceUsd: 0.00001124,
        change24h: 24.85,
        volume24h: 1850000000,
        marketCap: 4720000000,
        high24h: 0.00001180,
        low24h: 0.00000890,
        category: 'Meme',
        networkId: 'ethereum',
        contractAddress: '0x6982508145454Ce325dDbE47a25d4ec3d2311933',
        rank: 8,
        sparkline: [8.9, 9.2, 9.8, 10.2, 10.6, 10.9, 11.1, 11.24],
      ),
      const MarketItem(
        id: 'fet',
        symbol: 'FET',
        name: 'Artificial Superintelligence',
        priceUsd: 1.42,
        change24h: 16.32,
        volume24h: 460000000,
        marketCap: 3580000000,
        high24h: 1.48,
        low24h: 1.21,
        category: 'AI',
        networkId: 'ethereum',
        rank: 9,
        sparkline: [1.21, 1.25, 1.28, 1.33, 1.36, 1.39, 1.41, 1.42],
      ),
      const MarketItem(
        id: 'uni',
        symbol: 'UNI',
        name: 'Uniswap',
        priceUsd: 7.85,
        change24h: 5.62,
        volume24h: 310000000,
        marketCap: 4710000000,
        high24h: 8.10,
        low24h: 7.40,
        category: 'DeFi',
        networkId: 'ethereum',
        contractAddress: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
        rank: 10,
        sparkline: [7.4, 7.5, 7.45, 7.6, 7.7, 7.65, 7.8, 7.85],
      ),
      const MarketItem(
        id: 'wif',
        symbol: 'WIF',
        name: 'dogwifhat',
        priceUsd: 1.84,
        change24h: -8.45,
        volume24h: 520000000,
        marketCap: 1840000000,
        high24h: 2.05,
        low24h: 1.79,
        category: 'Meme',
        networkId: 'solana',
        rank: 11,
        sparkline: [2.05, 2.0, 1.95, 1.91, 1.88, 1.86, 1.85, 1.84],
      ),
      const MarketItem(
        id: 'near',
        symbol: 'NEAR',
        name: 'NEAR Protocol',
        priceUsd: 4.82,
        change24h: -4.12,
        volume24h: 280000000,
        marketCap: 5800000000,
        high24h: 5.12,
        low24h: 4.75,
        category: 'AI',
        networkId: 'ethereum',
        rank: 12,
        sparkline: [5.12, 5.05, 4.98, 4.92, 4.89, 4.85, 4.83, 4.82],
      ),
      const MarketItem(
        id: 'sui',
        symbol: 'SUI',
        name: 'Sui',
        priceUsd: 0.985,
        change24h: 12.80,
        volume24h: 390000000,
        marketCap: 2650000000,
        high24h: 1.02,
        low24h: 0.86,
        category: 'Layer 1',
        networkId: 'ethereum',
        rank: 13,
        sparkline: [0.86, 0.88, 0.91, 0.93, 0.95, 0.96, 0.97, 0.985],
      ),
      const MarketItem(
        id: 'arb',
        symbol: 'ARB',
        name: 'Arbitrum',
        priceUsd: 0.582,
        change24h: -3.20,
        volume24h: 180000000,
        marketCap: 2040000000,
        high24h: 0.610,
        low24h: 0.575,
        category: 'Layer 2',
        networkId: 'ethereum',
        contractAddress: '0x912CE59144191C1204E64559FE8253a0e49E6548',
        rank: 14,
        sparkline: [0.61, 0.60, 0.59, 0.59, 0.585, 0.58, 0.583, 0.582],
      ),
      const MarketItem(
        id: 'quick',
        symbol: 'QUICK',
        name: 'QuickSwap',
        priceUsd: 0.0485,
        change24h: 18.90,
        volume24h: 45000000,
        marketCap: 34000000,
        high24h: 0.0510,
        low24h: 0.0400,
        category: 'DeFi',
        networkId: 'polygon',
        contractAddress: '0xB5C064F955D8e7F38fE0460C556a72987494eE17',
        rank: 15,
        sparkline: [0.040, 0.042, 0.044, 0.045, 0.046, 0.047, 0.048, 0.0485],
      ),
      const MarketItem(
        id: 'cake',
        symbol: 'CAKE',
        name: 'PancakeSwap',
        priceUsd: 2.15,
        change24h: 7.45,
        volume24h: 88000000,
        marketCap: 580000000,
        high24h: 2.22,
        low24h: 1.98,
        category: 'DeFi',
        networkId: 'bnb',
        contractAddress: '0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82',
        rank: 16,
        sparkline: [1.98, 2.02, 2.05, 2.08, 2.10, 2.12, 2.14, 2.15],
      ),
      const MarketItem(
        id: 'aave',
        symbol: 'AAVE',
        name: 'Aave',
        priceUsd: 132.50,
        change24h: 9.85,
        volume24h: 210000000,
        marketCap: 1980000000,
        high24h: 136.0,
        low24h: 120.0,
        category: 'DeFi',
        networkId: 'ethereum',
        contractAddress: '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9',
        rank: 17,
        sparkline: [12.0, 12.3, 12.5, 12.8, 13.0, 13.1, 13.2, 13.25],
      ),
      const MarketItem(
        id: 'doge',
        symbol: 'DOGE',
        name: 'Dogecoin',
        priceUsd: 0.1045,
        change24h: -1.25,
        volume24h: 760000000,
        marketCap: 15200000000,
        high24h: 0.1080,
        low24h: 0.1030,
        category: 'Meme',
        networkId: 'bnb',
        rank: 18,
        sparkline: [0.108, 0.107, 0.106, 0.105, 0.104, 0.1045, 0.104, 0.1045],
      ),
    ];
  }

  void _loadFavorites() {
    if (_storageService != null) {
      final saved = _storageService!.getString('market_favorites');
      if (saved != null && saved.isNotEmpty) {
        try {
          final list = (jsonDecode(saved) as List).cast<String>();
          _favoriteIds = list.toSet();
        } catch (_) {}
      }
    }
  }

  void _saveFavorites() {
    if (_storageService != null) {
      _storageService!.setString('market_favorites', jsonEncode(_favoriteIds.toList()));
    }
  }

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void setTab(MarketTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void setEcosystem(String ecosystem) {
    _selectedEcosystem = ecosystem;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSort(MarketSortField field) {
    if (_sortField != field) {
      _sortField = field;
      _sortOrder = MarketSortOrder.descending;
    } else {
      if (_sortOrder == MarketSortOrder.descending) {
        _sortOrder = MarketSortOrder.ascending;
      } else if (_sortOrder == MarketSortOrder.ascending) {
        _sortField = MarketSortField.none;
        _sortOrder = MarketSortOrder.none;
      } else {
        _sortOrder = MarketSortOrder.descending;
      }
    }
    notifyListeners();
  }

  Future<void> refreshMarket() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;
    notifyListeners();
  }

  List<MarketItem> get displayedItems {
    List<MarketItem> list = _allItems.map((item) {
      return item.copyWith(isFavorite: _favoriteIds.contains(item.id));
    }).toList();

    // 1. Tab Filtering
    switch (_currentTab) {
      case MarketTab.watchlist:
        list = list.where((item) => _favoriteIds.contains(item.id)).toList();
        break;
      case MarketTab.hot:
        list.sort((a, b) => b.marketCap.compareTo(a.marketCap));
        break;
      case MarketTab.gainers:
        list = list.where((item) => item.change24h > 0).toList();
        list.sort((a, b) => b.change24h.compareTo(a.change24h));
        break;
      case MarketTab.losers:
        list = list.where((item) => item.change24h < 0).toList();
        list.sort((a, b) => a.change24h.compareTo(b.change24h));
        break;
      case MarketTab.newListings:
        list = list.reversed.toList();
        break;
      case MarketTab.ecosystem:
        if (_selectedEcosystem != 'all') {
          list = list.where((item) {
            final eco = _selectedEcosystem.toLowerCase();
            return item.networkId.toLowerCase() == eco || item.category.toLowerCase() == eco;
          }).toList();
        }
        break;
    }

    // 2. Search Query Filtering
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((item) {
        return item.symbol.toLowerCase().contains(q) ||
            item.name.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q) ||
            (item.contractAddress != null && item.contractAddress!.toLowerCase().contains(q));
      }).toList();
    }

    // 3. User Column Sorting
    if (_sortField != MarketSortField.none && _sortOrder != MarketSortOrder.none) {
      final isAsc = _sortOrder == MarketSortOrder.ascending;
      switch (_sortField) {
        case MarketSortField.name:
          list.sort((a, b) => isAsc ? a.symbol.compareTo(b.symbol) : b.symbol.compareTo(a.symbol));
          break;
        case MarketSortField.price:
          list.sort((a, b) => isAsc ? a.priceUsd.compareTo(b.priceUsd) : b.priceUsd.compareTo(a.priceUsd));
          break;
        case MarketSortField.change:
          list.sort((a, b) => isAsc ? a.change24h.compareTo(b.change24h) : b.change24h.compareTo(a.change24h));
          break;
        case MarketSortField.volume:
          list.sort((a, b) => isAsc ? a.volume24h.compareTo(b.volume24h) : b.volume24h.compareTo(a.volume24h));
          break;
        case MarketSortField.none:
          break;
      }
    }

    return list;
  }
}
