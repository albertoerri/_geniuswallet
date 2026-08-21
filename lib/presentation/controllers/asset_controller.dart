import 'package:flutter/material.dart';
import '../../domain/models/network.dart';
import '../../domain/models/token.dart';
import '../../domain/models/wallet.dart';
import '../../repositories/asset_repository.dart';

class AssetController extends ChangeNotifier {
  final IAssetRepository _repository;

  List<Token> _tokens = [];
  double _totalBalanceUsd = 0.0;
  bool _isLoading = false;
  int _selectedSubTab = 0; // 0: Assets, 1: DeFi, 2: NFT
  bool _hideSmallBalances = false;
  bool _sortByBalance = false;
  final Map<String, double> _walletBalances = {};

  AssetController({required IAssetRepository repository})
      : _repository = repository;

  List<Token> get tokens => _tokens;
  double get totalBalanceUsd => _totalBalanceUsd;
  bool get isLoading => _isLoading;
  int get selectedSubTab => _selectedSubTab;
  bool get hideSmallBalances => _hideSmallBalances;
  bool get sortByBalance => _sortByBalance;

  List<Token> get displayedTokens {
    var list = List<Token>.from(_tokens);
    if (_hideSmallBalances) {
      list = list.where((t) => t.fiatValue >= 1.0 || t.balance > 0.01).toList();
    }
    if (_sortByBalance) {
      list.sort((a, b) => b.fiatValue.compareTo(a.fiatValue));
    }
    return list;
  }

  void toggleHideSmallBalances() {
    _hideSmallBalances = !_hideSmallBalances;
    notifyListeners();
  }

  void toggleSortByBalance() {
    _sortByBalance = !_sortByBalance;
    notifyListeners();
  }

  void addCustomToken(Token token) {
    if (!_tokens.any((t) => t.symbol.toUpperCase() == token.symbol.toUpperCase())) {
      _tokens.add(token);
      _totalBalanceUsd += token.fiatValue;
      notifyListeners();
    }
  }

  double getWalletBalance(String walletId) => _walletBalances[walletId] ?? 0.0;

  String formatUsd(double amount) {
    if (amount == 0) return r'$0.00';
    if (amount < 0.01) return r'<$0.01';
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '\$$whole.${parts[1]}';
  }

  void setSubTab(int tab) {
    if (_selectedSubTab != tab) {
      _selectedSubTab = tab;
      notifyListeners();
    }
  }

  Future<void> loadAssets({
    required Network network,
    required String walletAddress,
    String? walletId,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tokenList = await _repository.getTokensForWallet(
        network: network,
        walletAddress: walletAddress,
        forceRefresh: forceRefresh,
      );

      _tokens = tokenList;
      double total = 0.0;
      for (final t in tokenList) {
        total += t.fiatValue;
      }
      _totalBalanceUsd = total;
      if (walletId != null) {
        _walletBalances[walletId] = total;
      }
    } catch (_) {
      // Gracefully retain existing state or default tokens
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> preloadWalletBalances({
    required List<Wallet> wallets,
    required List<Network> networks,
  }) async {
    for (final wallet in wallets) {
      final network = networks.firstWhere(
        (n) => n.id.toLowerCase() == wallet.networkId.toLowerCase(),
        orElse: () => networks.first,
      );
      try {
        final total = await _repository.getTotalBalanceUsd(
          network: network,
          walletAddress: wallet.address,
        );
        _walletBalances[wallet.id] = total;
      } catch (_) {
        _walletBalances[wallet.id] = 0.0;
      }
    }
    notifyListeners();
  }

  Future<void> claimFaucet({
    required Network network,
    required String walletAddress,
    required String walletId,
    required String tokenSymbol,
    required double amount,
  }) async {
    await _repository.claimFaucetTokens(
      network: network,
      walletAddress: walletAddress,
      tokenSymbol: tokenSymbol,
      amount: amount,
    );
    await loadAssets(
      network: network,
      walletAddress: walletAddress,
      walletId: walletId,
      forceRefresh: true,
    );
  }

  Future<void> updateBalance({
    required Network network,
    required String walletAddress,
    required String walletId,
    required String tokenSymbol,
    required double newBalance,
  }) async {
    await _repository.updateTokenBalance(
      network: network,
      walletAddress: walletAddress,
      tokenSymbol: tokenSymbol,
      newBalance: newBalance,
    );
    await loadAssets(
      network: network,
      walletAddress: walletAddress,
      walletId: walletId,
      forceRefresh: true,
    );
  }
}
