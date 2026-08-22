import 'package:shared_preferences/shared_preferences.dart';

enum EnvironmentMode {
  live, // Real on-chain Polygon / EVM Mainnet
  simulation, // Local simulation for offline demo/testing
}

abstract class IEnvironmentService {
  EnvironmentMode get currentMode;
  bool get isLive;
  Future<void> setMode(EnvironmentMode mode);
}

class EnvironmentService implements IEnvironmentService {
  static const String _key = 'app_environment_mode';
  final SharedPreferences? _prefs;
  EnvironmentMode _currentMode = EnvironmentMode.live;

  EnvironmentService({SharedPreferences? prefs}) : _prefs = prefs {
    _loadInitialMode();
  }

  void _loadInitialMode() {
    if (_prefs != null) {
      final saved = _prefs!.getString(_key);
      if (saved == 'simulation') {
        _currentMode = EnvironmentMode.simulation;
      } else {
        _currentMode = EnvironmentMode.live;
      }
    }
  }

  @override
  EnvironmentMode get currentMode => _currentMode;

  @override
  bool get isLive => _currentMode == EnvironmentMode.live;

  @override
  Future<void> setMode(EnvironmentMode mode) async {
    _currentMode = mode;
    if (_prefs != null) {
      await _prefs!.setString(_key, mode == EnvironmentMode.simulation ? 'simulation' : 'live');
    }
  }
}
