import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/wallet.dart';

abstract class ILocalStorageService {
  Future<List<Wallet>> getWallets();
  Future<void> saveWallets(List<Wallet> wallets);
  Future<String?> getActiveWalletId();
  Future<void> setActiveWalletId(String? walletId);
  Future<String?> getSelectedNetworkId();
  Future<void> setSelectedNetworkId(String networkId);
  Future<void> clearAll();
}

class LocalStorageService implements ILocalStorageService {
  static const String _walletsKey = 'genius_wallets_list';
  static const String _activeWalletIdKey = 'genius_active_wallet_id';
  static const String _selectedNetworkIdKey = 'genius_selected_network_id';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  @override
  Future<List<Wallet>> getWallets() async {
    final rawJson = _prefs.getString(_walletsKey);
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded.map((item) => Wallet.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveWallets(List<Wallet> wallets) async {
    final rawJson = jsonEncode(wallets.map((w) => w.toJson()).toList());
    await _prefs.setString(_walletsKey, rawJson);
  }

  @override
  Future<String?> getActiveWalletId() async {
    return _prefs.getString(_activeWalletIdKey);
  }

  @override
  Future<void> setActiveWalletId(String? walletId) async {
    if (walletId == null) {
      await _prefs.remove(_activeWalletIdKey);
    } else {
      await _prefs.setString(_activeWalletIdKey, walletId);
    }
  }

  @override
  Future<String?> getSelectedNetworkId() async {
    return _prefs.getString(_selectedNetworkIdKey);
  }

  @override
  Future<void> setSelectedNetworkId(String networkId) async {
    await _prefs.setString(_selectedNetworkIdKey, networkId);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_walletsKey);
    await _prefs.remove(_activeWalletIdKey);
    await _prefs.remove(_selectedNetworkIdKey);
  }
}
