import 'package:flutter/material.dart';
import '../../services/environment_service.dart';

class EnvironmentController extends ChangeNotifier {
  final IEnvironmentService _service;

  EnvironmentController({required IEnvironmentService service}) : _service = service;

  EnvironmentMode get mode => _service.currentMode;
  bool get isLive => _service.isLive;

  Future<void> setMode(EnvironmentMode newMode) async {
    if (_service.currentMode != newMode) {
      await _service.setMode(newMode);
      notifyListeners();
    }
  }

  Future<void> toggleMode() async {
    final next = isLive ? EnvironmentMode.simulation : EnvironmentMode.live;
    await setMode(next);
  }
}
