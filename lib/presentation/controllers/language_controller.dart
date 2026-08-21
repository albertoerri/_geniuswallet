import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../storage/local_storage_service.dart';

enum AppLanguage {
  en('en', 'English'),
  zh('zh', '简体中文');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);
}

class LanguageController extends ChangeNotifier {
  final ILocalStorageService _storage;
  static const String _storageKey = 'app_selected_language';

  AppLanguage _currentLanguage = AppLanguage.en;

  LanguageController(this._storage) {
    _loadLanguage();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  String get languageCode => _currentLanguage.code;
  bool get isChinese => _currentLanguage == AppLanguage.zh;

  Future<void> _loadLanguage() async {
    final savedCode = _storage.getString(_storageKey);
    if (savedCode != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (l) => l.code == savedCode,
        orElse: () => AppLanguage.en,
      );
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    await _storage.setString(_storageKey, language.code);
    notifyListeners();
  }

  String tr(String key, {Map<String, String>? params}) {
    return AppStrings.get(key, _currentLanguage.code, params: params);
  }
}
